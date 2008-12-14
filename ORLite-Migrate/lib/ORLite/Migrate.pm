package ORLite::Migrate;

# See POD at end of file for documentation

use 5.006;
use strict;
use Carp         ();
use Params::Util qw{ _STRING _CLASS _HASH };
use DBI          ();
use ORLite       ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'ORLite';
}

sub import {
	my $class = ref $_[0] || $_[0];

	# Check for debug mode
	my $DEBUG = 0;
	if ( defined _STRING($_[-1]) and $_[-1] eq '-DEBUG' ) {
		$DEBUG = 1;
		pop @_;
	}

	# Check params and apply defaults
	my %params;
	if ( defined _STRING($_[1]) ) {
		# Migrate needs at least two params
		Carp::croak("ORLite::Migrate must be invoked in HASH form");
	} elsif ( _HASH($_[1]) ) {
		%params = %{ $_[1] };
	} else {
		Carp::croak("Missing, empty or invalid params HASH");
	}
	unless ( defined $params{create} ) {
		$params{create} = 0;
	}
	unless (
		defined _STRING($params{file})
		and (
			$params{create}
			or
			-f $params{file}
		)
	) {
		Carp::croak("Missing or invalid file param");
	}
	unless ( defined $params{readonly} ) {
		$params{readonly} = $params{create} ? 0 : ! -w $params{file};
	}
	unless ( defined $params{tables} ) {
		$params{tables} = 1;
	}
	unless ( defined $params{package} ) {
		$params{package} = scalar caller;
	}
	unless ( _CLASS($params{package}) ) {
		Carp::croak("Missing or invalid package class");
	}
	unless ( $params{timeline} and -d $params{timeline} and -r $params{timeline} ) {
		Carp::croak("Missing or invalid timeline directory");
	}

	# We don't support readonly databases
	if ( $params{readonly} ) {
		Carp::croak("ORLite::Migrate does not support readonly databases");
	}

	# Get the schema version
	my $file     = File::Spec->rel2abs($params{file});
	my $dsn      = "dbi:SQLite:$file";
	my $dbh      = DBI->connect($dsn);
	my $version  = $dbh->selectrow_arrayref('pragma user_version')->[0];
	$dbh->disconnect;

	# Build the migration plan
	my $timeline = File::Spec->rel2abs($params{timeline});
	my @plan = plan( $params{timeline}, $version );

	# Execute the migration plan
	if ( @plan ) {
		# Does the migration plan reach the required destination
		my $destination = $version + scalar(@plan);
		if ( exists $params{user_version} and $destination != $params{user_version} ) {
			die "Schema migration destination user_version mismatch (got $destination, wanted $params{user_version})";
		}

		# Load the modules needed for the migration
		require Probe::Perl;
		require File::pushd;
		require IPC::Run3;

		# Execute each script
		my $perl  = Probe::Perl->find_perl_interpreter;
		my $pushd = File::pushd::pushd($timeline);
		foreach my $patch ( @plan ) {
			my $stdin = "$file\n";
			if ( $DEBUG ) {
				print STDERR "Applying schema patch $patch...\n";
			}
			my $ok    = IPC::Run3::run3( [ $perl, $patch ], \$stdin, \undef, $DEBUG ? undef : \undef );
			unless ( $ok ) {
				Carp::croak("Migration patch $patch failed, database in unknown state");
			}
		}

		# Migration complete, set user_version to new state
		$dbh = DBI->connect($dsn);
		$dbh->do("pragma user_version = $destination");
		$dbh->disconnect;
	}

	# Hand off to the regular constructor
	return $class->SUPER::import( \%params, $DEBUG ? '-DEBUG' : () );
}





#####################################################################
# Simple Methods

sub patches {
	my $dir = shift;

	# Find all files in a directory
	local *DIR;
	opendir( DIR, $dir )       or die "opendir: $!";
	my @files = readdir( DIR ) or die "readdir: $!";
	closedir( DIR )            or die "closedir: $!";

	# Filter to get the patch set
	my @patches = ();
	foreach ( @files ) {
		next unless /^migrate-(\d+)\.pl$/;
		$patches["$1"] = $_;
	}

	return @patches;
}

sub plan {
	my $directory = shift;
	my $version   = shift;

	# Find the list of patches
	my @patches = patches( $directory );

	# Assemble the plan by integer stepping forwards
	# until we run out of timeline hits.
	my @plan = ();
	while ( $patches[++$version] ) {
		push @plan, $patches[$version];
	}

	return @plan;
}

1;

__END__

=pod

=head1 NAME

ORLite::Migrate - Extremely light weight SQLite-specific schema migration

=head1 DESCRIPTION

B<THIS CODE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE>

B<YOU HAVE BEEN WARNED!>

L<SQLite> is a light weight single file SQL database that provides an
excellent platform for embedded storage of structured data.

L<ORLite> is a light weight single file Object-Relational Mapper (ORM)
system specifically designed for (and limited to only) work with SQLite.

L<ORLite::Migrate> is a light weight single file Database Schema
Migration enhancement for L<ORLite>.



=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Migrate>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
