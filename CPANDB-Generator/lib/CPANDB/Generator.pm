package CPANDB::Generator;

=pod

=head1 NAME

CPANDB::Generator - Generator module for the CPAN Index Database

=head1 SYNOPSIS

  # Simplicity itself
  CPANDB::Generator->new->run;

=head1 DESCRIPTION

This is a module used to generate a unified index database, pulling in
data from various other sources to produce a single schema that contains
the essential elements from all of them.

It is uploaded to the CPAN for the purpose of full disclosure, or in case
the author gets hit by a bus. Generating the index database involves
downloading a number of relatively large SQLite datasets, the consumption
of several gigabytes of disk, and a fairly large amount of CPU time.

If you are interested in using the index database, you should
instead see the L<CPANDB> distribution.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use Carp                 ();
use File::Spec      3.30 ();
use File::Temp      0.21 ();
use File::Path      2.07 ();
use File::pushd     1.00 ();
use File::Remove    1.42 ();
use File::HomeDir   0.86 ();
use File::Basename       ();
use DBI            1.608 ();
use DBD::SQLite     1.25 ();
use CPAN::SQLite   0.197 ();

our $VERSION = '0.03';

use Object::Tiny 1.06 qw{
	cpan
	urllist
	sqlite
	dbh
};

use CPANDB::Generator::GetIndex ();





#####################################################################
# Constructor

=pod

=head2 new

  my $cpandb = CPANDB::Generator->new(
      cpan   => '/root/.cpan',
      sqlite => '/root/CPANDB.sqlite',
  );

Creates a new generation object.

The optional C<cpan> param identifies the path to your
cpan operating directory. By default, a fresh one will be
generated in a temporary directory, and deleted at the end of
the generation run.

The optional C<sqlite> param specifies where the SQLite database
should be written to. By default, this will be to a standard
location in your home directory.

Returns a new B<CPANDB::Generator> object.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Default the CPAN path to a temp directory,
	# so that we don't disturb any existing files.
	unless ( defined $self->cpan ) {
		$self->{cpan} = File::Temp::tempdir( CLEANUP => 1 );
	}

	# Establish where we will be writing to
	unless ( defined $self->sqlite ) {
		$self->{sqlite} = File::Spec->catdir(
			File::HomeDir->my_data,
			($^O eq 'MSWin32' ? 'Perl' : '.perl'),
			'CPANDB-Generator',
			'CPANDB-Generator.sqlite',
		);
	}

	return $self;
}

=pod

=head2 dir

The C<dir> method returns the directory that the SQLite
database will be written into.

=cut

sub dir {
	File::Basename::dirname($_[0]->sqlite);
}

=pod

=head2 dsn

The C<dsn> method returns the L<DBI> DSN that is used to connect
to the generated database.

=cut

sub dsn {
	"DBI:SQLite:" . $_[0]->sqlite
}

=pod

=head2 cpandb_sql

Once it has been fetched or updated from your CPAN mirror, the
C<cpandb_sql> method returns the location of the L<CPAN::SQLite>
database used by the CPAN client.

This database is used as the source of the information that forms
the core of the unified index database, and that the rest of the
data will be decorated around.

=cut

sub cpandb_sql {
	File::Spec->catfile($_[0]->cpan, 'cpandb.sql');
}





#####################################################################
# Main Methods

=pod

=head2 run

The C<run> method executes the process that will produce and fill the
final database.

=cut

sub run {
	my $self = shift;

	# Create the output directory
	File::Path::make_path($self->dir);
	unless ( -d $self->dir ) {
		Carp::croak("Failed to create '" . $self->dir . "'");
	}

	# Clear the database if it already exists
	if ( -f $self->sqlite ) {
		File::Remove::remove($self->sqlite);
	}
	if ( -f $self->sqlite ) {
		Carp::croak("Failed to clear " . $self->sqlite);
	}

	# Connect to the database
	unless ( $self->{dbh} = DBI->connect($self->dsn) ) {
		Carp::croak("connect: \$DBI::errstr");
	}

	# Refresh the CPAN index database
	my $update = CPANDB::Generator::GetIndex->new(
		cpan    => $self->cpan,
		urllist => $self->urllist,
	)->delegate;
	unless ( -f $self->cpandb_sql ) {
		Carp::croak("Failed to fetch CPAN index");
	}

	# Load the CPAN Uploads database
	require ORDB::CPANUploads;
	ORDB::CPANUploads->import;

	# Load the CPAN META.yml database
	require ORDB::CPANMeta;
	ORDB::CPANMeta->import;

	# Attach the various databases
	$self->do( "ATTACH DATABASE ? AS cpandb", {}, $self->cpandb_sql         );
	$self->do( "ATTACH DATABASE ? AS upload", {}, ORDB::CPANUploads->sqlite );
	$self->do( "ATTACH DATABASE ? AS meta",   {}, ORDB::CPANMeta->sqlite    );

	# Pre-process the cpandb data to produce cleaner intermediate
	# temp tables that produce better joins later on.
	$self->do(<<'END_SQL');
CREATE TEMPORARY TABLE t_distribution AS
SELECT
	d.dist_name as dist,
	d.dist_vers as version,
	a.cpanid as author,
	a.cpanid || '/' || d.dist_file as release
FROM
	auths a,
	dists d
WHERE
	a.auth_id = d.auth_id
END_SQL

	# Pre-process the uploads data to produce a cleaner intermediate
	# temp table that won't break the joins we'll need to do later on.
	$self->do(<<'END_SQL');
CREATE TEMPORARY TABLE t_uploaded AS
SELECT
	author || '/' || filename as release,
	DATE(released, 'unixepoch') AS uploaded
FROM upload.uploads
END_SQL

	# Index the temporary tables so our joins don't take forever
	$self->do('CREATE INDEX t_uploaded__release ON t_uploaded ( release )');
	$self->do('CREATE INDEX t_distribution__release ON t_distribution ( release )');

	# Create the author table
	$self->do(<<'END_SQL');
CREATE TABLE author (
	author TEXT NOT NULL PRIMARY KEY,
	name TEXT NOT NULL
)
END_SQL

	# Fill the author table
	$self->do(<<'END_SQL');
INSERT INTO author
SELECT
	cpanid AS author,
	fullname AS name
FROM cpandb.auths
END_SQL

	# Create the distribution table
	$self->do(<<'END_SQL');
CREATE TABLE distribution (
	distribution TEXT NOT NULL PRIMARY KEY,
	version TEXT NULL,
	author TEXT NOT NULL,
	release TEXT NOT NULL,
	uploaded TEXT NOT NULL,
	FOREIGN KEY ( author ) REFERENCES author ( author )
)
END_SQL

	# Fill the distribution table
	$self->do(<<'END_SQL');
INSERT INTO distribution
SELECT
	d.dist as distribution,
	d.version as version,
	d.author as author,
	d.release as release,
	u.uploaded as uploaded
FROM
	t_distribution d,
	t_uploaded u
WHERE
	d.release = u.release
END_SQL

	# Create the module table
	$self->do(<<'END_SQL');
CREATE TABLE module (
	module TEXT NOT NULL PRIMARY KEY,
	version TEXT NULL,
	distribution TEXT NOT NULL,
	FOREIGN KEY ( distribution ) REFERENCES distribution ( distribution )
)
END_SQL

	# Fill the module table
	$self->do(<<'END_SQL');
INSERT INTO module
SELECT
	m.mod_name as module,
	m.mod_vers as version,
	d.dist_name as distribution
FROM
	mods m,
	dists d
WHERE
	d.dist_id = m.dist_id
END_SQL

	return 1;
}

sub do {
	my $self = shift;
	my $dbh  = $self->dbh;
	unless ( $dbh->do(@_) ) {
		Carp::croak("Database Error: " . $dbh->errstr);
	}
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANDB-Generator>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
