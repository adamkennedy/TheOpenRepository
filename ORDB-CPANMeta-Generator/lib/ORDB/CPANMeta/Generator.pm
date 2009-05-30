package ORDB::CPANMeta::Generator;

=pod

=head1 NAME

ORDB::CPANMeta::Generator - Generator for the CPAN Meta database

=head1 DESCRIPTION

This is the module that is used to generate the "CPAN Meta" database.

For more information, and to access this database as a consumer, see
the L<ORDB::CPANMeta> module.

=head1 METHODS

=cut

use 5.008005;
use strict;
use Carp                    ();
use File::Spec         3.29 ();
use File::Path         2.07 ();
use File::Remove       1.42 ();
use File::HomeDir      0.86 ();
use File::Basename        0 ();
use Parse::CPAN::Meta  1.39 ();
use Params::Util       0.38 qw{_HASH};
use DBI               1.608 ();
use CPAN::Mini        0.576 ();
use CPAN::Mini::Visit  0.03 ();
use Xtract::Publish    0.10 ();

our $VERSION = '0.01';

use Object::Tiny 1.06 qw{
	minicpan
	sqlite
	visit
	trace
	dbh
};





######################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor creates a new processor/generator.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Set the default path to the database
	unless ( defined $self->sqlite ) {
		$self->{sqlite} = File::Spec->catdir(
			File::HomeDir->my_data,
			($^O eq 'MSWin32' ? 'Perl' : '.perl'),
			'ORDB-CPANMeta-Generator',
			'metadb.sqlite',
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





######################################################################
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

	# Update the minicpan if needed
	if ( _HASH($self->minicpan) ) {
		CPAN::Mini->update_mirror(
			trace         => $self->trace,
			no_conn_cache => 1,
			%{$self->minicpan},
		);
		$self->{minicpan} = $self->minicpan->{local};
	}

	# Connect to the database
	my $dbh = DBI->connect($self->dsn);
	unless ( $dbh ) {
		Carp::croak("connect: \$DBI::errstr");
	}

	# Create the tables
	$dbh->do(<<'END_SQL');
CREATE TABLE meta_distribution (
	release TEXT NOT NULL,
	meta_name TEXT,
	meta_version TEXT,
	meta_abstract TEXT,
	meta_generated TEXT,
	meta_from TEXT,
	meta_license TEXT
);
END_SQL

	$dbh->do(<<'END_SQL');
CREATE TABLE meta_dependency (
	release TEXT NOT NULL,
	phase TEXT NOT NULL,
	module TEXT NOT NULL,
	version TEXT NULL
)
END_SQL

	# Run the visitor to generate the database
	$dbh->begin_work;
	my $counter   = 0;
	my @meta_dist = ();
	my @meta_deps = ();
	my $visitor   = CPAN::Mini::Visit->new(
		minicpan => $self->minicpan,
		callback => sub {
			print STDERR "$_[0]->{dist}\n" if $self->trace;
			my $the  = shift;
			my @deps = ();
			my $dist = {
				release => $the->{dist}
			};
			my @yaml = eval {
				Parse::CPAN::Meta::LoadFile(
					File::Spec->catfile(
						$the->{tempdir}, 'META.yml',
					)
				);
			};
			unless ( $@ ) {
				$dist->{meta_name}      = $yaml[0]->{name};
				$dist->{meta_version}   = $yaml[0]->{version};
				$dist->{meta_abstract}  = $yaml[0]->{abstract};
				$dist->{meta_generated} = $yaml[0]->{generated_by};
				$dist->{meta_from}      = $yaml[0]->{version_from};
				$dist->{meta_license}   = $yaml[0]->{license},

				my $requires = $yaml[0]->{requires} || {};
				$requires = { $requires => 0 } unless ref $requires;
				push @deps, map { +{
					release => $the->{dist},
					phase   => 'runtime',
					module  => $_,
					version => $requires->{$_},
				} } sort keys %$requires;

				my $build = $yaml[0]->{build_requires} || {};
				$build = { $build => 0 } unless ref $build;
				push @deps, map { +{
					release => $the->{dist},
					phase   => 'build',
					module  => $_,
					version => $build->{$_},
				} } sort keys %$build;

				my $configure = $yaml[0]->{configure_requires} || {};
				$configure = { $configure => 0 } unless ref $configure;
				push @deps, map { +{
					release => $the->{dist},
					phase   => 'configure',
					module  => $_,
					version => $configure->{$_},
				} } sort keys %$configure;
			}
			$dbh->do(
				'INSERT INTO meta_distribution VALUES ( ?, ?, ?, ?, ?, ?, ? )', {},
				$dist->{release},
				$dist->{meta_name},
				$dist->{meta_version},
				$dist->{meta_abstract},
				$dist->{meta_generated},
				$dist->{meta_from},
				$dist->{meta_license},
			);
			foreach ( @deps ) {
				$dbh->do(
					'INSERT INTO meta_dependency VALUES ( ?, ?, ?, ? )', {},
					$_->{release},
					$_->{phase},
					$_->{module},
					$_->{version},
				);
			}
			unless ( ++$counter % 100 ) {
				$dbh->commit;
				$dbh->begin_work;
			}
		},
	);
	$visitor->run;
	$dbh->commit;

	# Publish the database to the current directory
	print STDERR "Publishing the generated database...\n" if $self->trace;
	Xtract::Publish->new(
		from   => $self->sqlite,
		sqlite => 'cpanmeta.sqlite',
		trace  => 1,
		raw    => 0,
		gz     => 1,
		bz2    => 1,
		lz     => 1,
	)->run;

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORDB-CPANMeta-Generator>

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
