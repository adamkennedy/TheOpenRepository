package ORLite::Mirror;

use 5.006;
use strict;
use Carp                          ();
use File::Copy                    ();
use File::Spec               0.80 ();
use File::Path               2.04 ();
use File::Remove             1.42 ();
use File::HomeDir            0.69 ();
use File::ShareDir           1.00 ();
use Params::Util             0.33 qw{ _STRING _NONNEGINT _HASH };
use IO::Uncompress::Gunzip  2.008 ();
use IO::Uncompress::Bunzip2 2.008 ();
use LWP::UserAgent          5.806 ();
use LWP::Online              1.07 ();
use ORLite                   1.22 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.15';
	@ISA     = 'ORLite';
}





#####################################################################
# Code Generation

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
		# Support the short form "use ORLite 'http://.../db.sqlite'"
		%params = (
			url      => $_[1],
			readonly => undef, # Automatic
			package  => undef, # Automatic
		);
	} elsif ( _HASH($_[1]) ) {
		%params = %{ $_[1] };
	} else {
		Carp::croak("Missing, empty or invalid params HASH");
	}

	# Check for incompatible create option
	if ( $params{create} and ref($params{create}) ) {
		Carp::croak("Cannot supply complex 'create' param to ORLite::Mirror");
	}

	# Autodiscover the package if needed
	unless ( defined $params{package} ) {
		$params{package} = scalar caller;
	}
	my $pversion = $params{package}->VERSION;
	my $agent    = "$params{package}/$pversion",

	# Normalise boolean settings
	my $show_progress = $params{show_progress} ? 1 : 0;

	# Find the maximum age for the local database copy
	my $maxage = delete $params{maxage};
	unless ( defined $maxage ) {
		$maxage = 86400;
	}
	unless ( _NONNEGINT($maxage) ) {
		Carp::croak("Invalid maxage param '$maxage'");
	}
	
	# Find the stub database
	my $stub = delete $params{stub};
	if ( $stub ) {
		$stub = File::ShareDir::module_file(
			$params{package} => 'stub.db'
		);
		unless ( -f $stub ) {
			Carp::croak("Stub database '$stub' does not exist");
		}
	}

	# Check when we should update
	my $update = delete $params{update};
	unless ( defined $update ) {
		$update = 'compile';
	}
	unless ( $update =~ /^(?:compile|connect)$/ ) {
		Carp::croak("Invalid update param '$update'");
	}

	# Determine the mirror database directory
	my $dir = File::Spec->catdir(
		File::HomeDir->my_data,
		($^O eq 'MSWin32' ? 'Perl' : '.perl'),
		'ORLite-Mirror',
	);

	# Create it if needed
	unless ( -e $dir ) {
		File::Path::mkpath( $dir, { verbose => 0 } );
	}

	# Determine the mirror database file
	my $file = $params{package} . '.sqlite';
	$file =~ s/::/-/g;
	my $db = File::Spec->catfile( $dir, $file );

	# Download compressed files with their extention first
	my $url  = delete $params{url};
	my $path = ($url =~ /(\.gz|\.bz2)$/) ? "$db$1" : $db;

	# Are we online (fake to true if the URL is local)
	my $online = !! ( $url =~ /^file:/ or LWP::Online::online() );
	unless ( $online or -f $path or $stub ) {
		# Don't have the file and can't get it
		Carp::croak("Cannot fetch database without an internet connection");
	}

	# If the file doesn't exist, sync at compile time.
	my $STUBBED = 0;
	unless ( -f $db ) {
		if ( $update eq 'connect' and $stub ) {
			# Fallback option, use the stub
			File::Copy::copy( $stub => $db ) or
			Carp::croak("Failed to copy in stub database");
			$STUBBED = 1;
		} else {
			$update = 'compile';
		}
	}

	# Don't update if the file is newer than the maxage
	my $mtime = (stat($path))[9] || 0;
	my $old   = (time - $mtime) > $maxage;
	if ( not $STUBBED and -f $path ? ($old and $online) : 1 ) {
		# Create the default useragent
		my $useragent = delete $params{useragent};
		unless ( $useragent ) {
			$useragent = LWP::UserAgent->new(
				agent         => $agent,
				timeout       => 30,
				show_progress => $show_progress,
			);
		}

		# Fetch the archive
		my $response = $useragent->mirror( $url => $path );
		unless ( $response->is_success or $response->code == 304 ) {
			Carp::croak("Error: Failed to fetch $url");
		}

		# Decompress if we pulled an archive
		my $refreshed = 0;
		if ( $path =~ /\.gz$/ ) {
			unless ( $response->code == 304 and -f $path ) {
				IO::Uncompress::Gunzip::gunzip(
					$path      => $db,
					BinModeOut => 1,
				) or Carp::croak("gunzip($path) failed");
				$refreshed = 1;
			}
		} elsif ( $path =~ /\.bz2$/ ) {
			unless ( $response->code == 304 and -f $path ) {
				IO::Uncompress::Bunzip2::bunzip2(
					$path      => $db,
					BinModeOut => 1,
				) or Carp::croak("bunzip2($path) failed");
				$refreshed = 1;
			}
		}

		# If we updated the file, add any extra indexes that we need
		if ( $refreshed and $params{index} ) {
			my $dbh = DBI->connect("DBI:SQLite:$db", undef, undef, {
				RaiseError => 1,
				PrintError => 1,
			} );
			foreach ( @{$params{index}} ) {
				my ($table, $column) = split /\./, $_;
				$dbh->do("CREATE INDEX idx__${table}__${column} ON $table ( $column )");
			}
			$dbh->disconnect;
		}
	}

	# Mirrored databases are always readonly.
	$params{file}     = $db;
	$params{readonly} = 1;

	# If and only if they update at connect-time, replace the
	# original dbh method with one that syncs the database.
	if ( $update eq 'connect' ) {
		# Generate the user_version checking fragment
		my $check_version = '';
		if ( $params{user_version} ) {
			$check_version = <<"END_PERL";
	unless ( \$class->pragma('user_version') == $params{user_version} ) {

	}

END_PERL
		}

		# Generate the archive decompression fragment
		my $decompress = '';
		if ( $path =~ /\.gz$/ ) {
			$decompress = <<"END_PERL";
	unless ( \$response->code == 304 and -f \$PATH ) {
		my \$sqlite = \$class->sqlite;
		require File::Remove;
		unless ( File::Remove::remove(\$sqlite) ) {
			Carp::croak("Error: Failed to flush '\$sqlite'");
		}

		require IO::Uncompress::Gunzip;
		IO::Uncompress::Gunzip::gunzip(
			\$PATH => \$sqlite,
			BinModeOut => 1,
		) or Carp::croak("Error: gunzip(\$PATH) failed");
	}

END_PERL
		} elsif ( $path =~ /\.bz2$/ ) {
			$decompress = <<"END_PERL";
	unless ( \$response->code == 304 and -f \$PATH ) {
		my \$sqlite = \$class->sqlite;
		require File::Remove;
		unless ( File::Remove::remove(\$sqlite) ) {
			Carp::croak("Error: Failed to flush '\$sqlite'");
		}

		require IO::Uncompress::Bunzip2;
		IO::Uncompress::Bunzip2::bunzip2(
			\$PATH => \$sqlite,
			BinModeOut => 1,
		) or Carp::croak("Error: bunzip2(\$PATH) failed");
	}

END_PERL
		}

		# Combine to get the final merged append code
		$params{append} = <<"END_PERL";
use Carp ();

use vars qw{ \$REFRESHED };
BEGIN {
	\$REFRESHED = 0;
	delete \$$params{package}::{DBH};
}

my \$URL  = '$url';
my \$PATH = '$path';

sub refresh {
	my \$class     = shift;
	my \%param     = \@_;
	require LWP::UserAgent;
	my \$useragent = LWP::UserAgent->new(
		agent         => '$agent',
		timeout       => 30,
		show_progress => !! \$param{show_progress},
	);

	# Flush the existing database
	require File::Remove;
	if ( -f \$PATH and not File::Remove::remove(\$PATH) ) {
		Carp::croak("Error: Failed to flush '\$PATH'");
	}

	# Fetch the archive
	my \$response = \$useragent->mirror( \$URL => \$PATH );
	unless ( \$response->is_success or \$response->code == 304 ) {
		Carp::croak("Error: Failed to fetch '\$URL'");
	}

$decompress
	\$REFRESHED = 1;

$check_version
	return 1;
}

no warnings 'redefine';
sub connect {
	my \$class = shift;
	unless ( \$REFRESHED ) {
		\$class->refresh(
			show_progress => $show_progress,
		);
	}
	DBI->connect(\$class->dsn);
}
END_PERL
	}

	# Hand off to the main ORLite class.
	$class->SUPER::import(
		\%params,
		$DEBUG ? '-DEBUG' : ()
	);
}

1;

=pod

=head1 NAME

ORLite::Mirror - Extend ORLite to support remote SQLite databases

=head1 SYNOPSIS

  # Regular ORLite on a readonly SQLite database
  use ORLite 'path/mydb.sqlite';
  
  # The equivalent for a remote SQLite database
  use ORLite::Mirror 'http://myserver/path/mydb.sqlite';
  
  # You can read compressed SQLite databases as well
  use ORLite::Mirror 'http://myserver/path/mydb.sqlite.gz';
  use ORLite::Mirror 'http://myserver/path/mydb.sqlite.bz2';
  
  (Of course you can only do one of the above)

=head1 DESCRIPTION

L<ORLite> provides a readonly ORM API when it loads a readonly SQLite
database from your local system.

By combining this capability with L<LWP>, L<ORLite::Mirror> goes one step
better and allows you to load a SQLite database from any arbitrary URI in
readonly form as well.

As demonstrated in the synopsis above, you using L<ORLite::Mirror> in the
same way, but provide a URL instead of a file name.

If the URL explicitly ends with a '.gz' or '.bz2' then L<ORLite::Mirror>
will decompress the file before loading it.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Mirror>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
