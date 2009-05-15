package CPANDB::Generator;

use 5.008005;
use strict;
use warnings;
use Carp               ();
use File::Spec    3.30 ();
use File::Temp    0.21 ();
use File::Path    2.07 ();
use File::pushd   1.00 ();
use File::Remove  1.42 ();
use File::HomeDir 0.86 ();
use File::Basename     ();
use DBI          1.608 ();
use DBD::SQLite   1.25 ();
use CPAN::SQLite 0.197 ();

our $VERSION = '0.01';

use Object::Tiny 1.06 qw{
	cpan
	sqlite
	dbh
};





#####################################################################
# Constructor

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

sub dir {
	File::Basename::dirname($_[0]->sqlite);
}

sub dsn {
	"DBI:SQLite:" . $_[0]->sqlite
}

sub cpandb_sql {
	File::Spec->catfile($_[0]->cpan, 'cpandb.sql');
}





#####################################################################
# Main Methods

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
	SCOPE: {
		local $SIG{__WARN__} = sub { };
		CPAN::SQLite->new(
			CPAN   => $self->cpan,
			db_dir => $self->cpan,
		)->index( setup => 1 );
	}

	# Load the CPAN Uploads database
	require ORDB::CPANUploads;
	ORDB::CPANUploads->import;

	# Attach the various databases
	$self->do( "ATTACH DATABASE ? AS cpandb", {}, $self->cpandb_sql );
	$self->do( "ATTACH DATABASE ? AS upload", {}, ORDB::CPANUploads->sqlite );

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
FROM auths
END_SQL

	# Create the distribution table
	$self->do(<<'END_SQL');
CREATE TABLE dist (
	id INTEGER NOT NULL PRIMARY KEY,
	dist TEXT NOT NULL,
	version TEXT NULL,
	author TEXT NOT NULL,
	file TEXT NOT NULL,
	released TEXT NOT NULL,
	FOREIGN KEY ( author ) REFERENCES author ( author )
)
END_SQL

	# Fill the distribution table
	$self->do(<<'END_SQL');
INSERT INTO dist
SELECT
	d.dist_name as dist,
	d.dist_vers as version,
	a.cpanid author,
	d.dist_file as file,
	date(u.released, 'unixepoch') as released
FROM
	auths a,
	dists d,
	upload.uploads u
WHERE
	a.auth_id = d.auth_id
	and
	d.dist_file = u.filename
END_SQL

	# Create the module table
	$self->do(<<'END_SQL');
CREATE TABLE module (
	module TEXT NOT NULL PRIMARY KEY,
	version TEXT NULL,
	dist TEXT NOT NULL,
	FOREIGN KEY ( dist ) REFERENCES dist ( dist )
)
END_SQL

	# Fill the module table
	$self->do(<<'END_SQL');
INSERT INTO module
SELECT
	m.mod_name as module,
	m.mod_vers as version,
	d.dist_name as dist
FROM
	mods m,
	dists d
WHERE
	d.dist_id = m.dist_id
END_SQL

	# Load

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
