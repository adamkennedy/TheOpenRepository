package ORDB::CPANMeta::Generator;

=pod

=head1 NAME

ORDB::CPANMeta::Generator - Generator for the CPAN Meta database

=head1 DESCRIPTION

This is the module that is used to generate the "CPAN Meta" database.

For more information, and to access this database as a consumer, see
the L<ORDB::CPANMeta> module.

The bulk of the work done in this module is actually achieved with:

L<CPAN::Mini> - Fetching the index and dist tarballs

L<CPAN::Mini::Visit> - Expanding and processing the tarballs

L<Xtract> - Preparing the SQLite database for distribution

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
use Params::Util       1.00 qw{_HASH};
use Getopt::Long       2.34 ();
use DBI               1.609 ();
use CPAN::Mini        0.576 ();
use CPAN::Mini::Visit  0.08 ();
use Xtract::Publish    0.10 ();

our $VERSION = '0.07';

use Object::Tiny 1.06 qw{
	minicpan
	sqlite
	publish
	visit
	trace
	delta
	prefer_bin
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

	# Set the default path to the publishing location
	unless ( exists $self->{publish} ) {
		$self->{publish} = 'cpanmeta';
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

=pod

=head2 run

The C<run> method executes the process that will produce and fill the
final database.

=cut

sub run {
	my $self = shift;

	# Normalise
	$self->{prefer_bin} = $self->prefer_bin ? 1 : 0;

	# Create the output directory
	File::Path::make_path($self->dir);
	unless ( -d $self->dir ) {
		Carp::croak("Failed to create '" . $self->dir . "'");
	}

	# Clear the database if it already exists
	unless ( $self->delta ) {
		if ( -f $self->sqlite ) {
			File::Remove::remove($self->sqlite);
		}
		if ( -f $self->sqlite ) {
			Carp::croak("Failed to clear " . $self->sqlite);
		}
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
CREATE TABLE IF NOT EXISTS meta_distribution (
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
CREATE TABLE IF NOT EXISTS meta_dependency (
	release TEXT NOT NULL,
	phase TEXT NOT NULL,
	module TEXT NOT NULL,
	version TEXT NULL
)
END_SQL

	### NOTE: This does nothing right now but will later.
	# Build the index of seen archives.
	# While building the index, remove entries
	# that are no longer in the minicpan.
	my $ignore = undef;
	if ( $self->delta ) {
		$dbh->begin_work;
		my %seen  = ();
		my $dists = $dbh->selectcol_arrayref(
			'SELECT DISTINCT release FROM meta_distribution'
		);
		foreach my $dist ( @$dists ) {
			my $one  = substr($dist, 0, 1);
			my $two  = substr($dist, 0, 2);
			my $path = File::Spec->catfile(
				$self->minicpan,
				'authors', 'id',
				$one, $two,
				split /\//, $dist,
			);
			if ( -f $path ) {
				# Add to the ignore list
				$seen{"$one/$two/$dist"} = 1;
				next;
			}

			# Clear the release from the database
			$dbh->do(
				'DELETE FROM meta_distribution WHERE release = ?',
				{}, $dist,
			);
		}
		$dbh->do(
			'DELETE FROM meta_dependency WHERE release NOT IN '
			. '( SELECT release FROM meta_distribution )',
		);
		$dbh->commit;

		# NOW we need to start ignoring something
		$ignore = [ sub { $seen{$_[0]} } ];
	}

	# Clear indexes for speed
	$self->drop_indexes( $dbh );

	# Run the visitor to generate the database
	$dbh->begin_work;
	my @meta_dist = ();
	my @meta_deps = ();
	my $visitor   = CPAN::Mini::Visit->new(
		acme       => 1,
		minicpan   => $self->minicpan,
		# This does nothing now but will later
		ignore     => $ignore,
		prefer_bin => $self->prefer_bin,
		callback   => sub {
			print STDERR "$_[0]->{dist}\n" if $self->trace;
			my $the  = shift;
			my @deps = ();
			my $dist = {
				release => $the->{dist},
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
				$requires = {
					$requires => 0,
				} unless ref $requires;
				push @deps, map { +{
					release => $the->{dist},
					phase   => 'runtime',
					module  => $_,
					version => $requires->{$_},
				} } sort keys %$requires;

				my $build = $yaml[0]->{build_requires} || {};
				$build = {
					$build => 0,
				} unless ref $build;
				push @deps, map { +{
					release => $the->{dist},
					phase   => 'build',
					module  => $_,
					version => $build->{$_},
				} } sort keys %$build;

				my $configure = $yaml[0]->{configure_requires} || {};
				$configure = {
					$configure => 0,
				} unless ref $configure;
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
			unless ( $the->{counter} % 100 ) {
				$dbh->commit;
				$dbh->begin_work;
			}
		},
	);
	$visitor->run;
	$dbh->commit;

	# Generate the indexes
	$self->create_indexes( $dbh );

	# Publish the database to the current directory
	unless ( defined $self->publish ) {
		print STDERR "Publishing the generated database...\n" if $self->trace;
		Xtract::Publish->new(
			from   => $self->sqlite,
			sqlite => $self->publish,
			trace  => $self->trace,
			raw    => 0,
			gz     => 1,
			bz2    => 1,
			lz     => 1,
		)->run;
	}

	return 1;
}





######################################################################
# Index Management

my @INDEX = (
	[ 'meta_distribution', 'release' ],
	[ 'meta_dependency',   'release' ],
	[ 'meta_dependency',   'phase'   ],
	[ 'meta_dependency',   'module'  ],
);

sub drop_indexes {
	my $self = shift;
	my $dbh  = shift;
	foreach my $i ( @INDEX ) {
		$dbh->do("DROP INDEX IF EXISTS $i->[0]__$i->[1]");
	}
	return 1;
}

sub create_indexes {
	my $self = shift;
	my $dbh  = shift;
	foreach my $i ( @INDEX ) {
		$self->create_index( $dbh, @$i );
	}
	return 1;
}

sub create_index {
	my $self = shift;
	my $dbh  = shift;
	my $t    = shift;
	my $c    = shift;
	$dbh->do("CREATE INDEX IF NOT EXISTS ${t}__${c} on $t ( $c )");
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
