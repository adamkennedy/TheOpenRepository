package ORLite::Mirror;

use 5.006;
use strict;
use Carp                    ();
use File::Spec              ();
use File::Path              ();
use File::Remove            ();
use File::HomeDir           ();
use LWP::UserAgent          ();
use Params::Util            qw{ _STRING _HASH };
use IO::Uncompress::Gunzip  ();
use IO::Uncompress::Bunzip2 ();
use ORLite                  ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.08';
	@ISA     = qw{ ORLite };
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
	unless ( defined $params{package} ) {
		$params{package} = scalar caller;
	}

	# Check when we should update
	unless ( defined $params{update} ) {
		$params{update} = 'compile';
	}
	unless ( $params{update} =~ /^(?:compile|connect)$/ ) {
		Carp::croak("Invalid update param '$params{update}'");
	}

	# Determine the mirror database location
	my $dir = File::Spec->catdir(
		File::HomeDir->my_data,
		'Perl', 'ORLite-Mirror'
	);
	my $file = $params{package} . '.sqlite';
	$file =~ s/::/-/g;
	my $path = File::Spec->catfile( $dir, $file );
	unless ( -f $path ) {
		# If the file doesn't exist, sync at compile time.
		$params{update} = 'compile';
	}

	# Create the directory
	unless ( -e $dir ) {
		File::Path::mkpath( $dir, { verbose => 0 } );
	}

	# Create the default useragent
	my $useragent = delete $params{useragent};
	unless ( $useragent ) {
		my $version = $params{package}->VERSION || 0;
		$useragent = LWP::UserAgent->new(
			timeout => 30,
			agent   => "$params{package}/$version",
		);
	}

	# Download compressed files with their extention first
	my $url = delete $params{url};
	if ( $url =~ /(\.gz|\.bz2)$/ ) {
		$path .= $1;
	}

	# Don't update if the file is newer than 24 hours
	my $archive = $path;
	if ( -f $path and (time - (stat($path))[9]) > 86400 ) {
		# Fetch the archive
		my $response = $useragent->mirror( $url => $path );
		unless ( $response->is_success or $response->code == 304 ) {
			Carp::croak("Error: Failed to fetch $url");
		}

		# Decompress if we pulled an archive
		if ( $path =~ /\.gz$/ ) {
			$path =~ s/\.gz$//;
			unless ( $response->code == 304 and -f $path ) {
				IO::Uncompress::Gunzip::gunzip(
					$archive   => $path,
					BinModeOut => 1,
				) or Carp::croak("gunzip($archive) failed");
			}
		} elsif ( $path =~ /\.bz2$/ ) {
			$path =~ s/\.bz2$//;
			unless ( $response->code == 304 and -f $path ) {
				IO::Uncompress::Bunzip2::bunzip2(
					$archive   => $path,
					BinModeOut => 1,
				) or Carp::croak("bunzip2($archive) failed");
			}
		}
	} else {
		if ( $path =~ /\.gz$/ ) {
			$path =~ s/\.gz$//;
		} elsif ( $path =~ /\.bz2$/ ) {
			$path =~ s/\.bz2$//;
		}
	}

	# Mirrored databases are always readonly.
	$params{file}     = $path;
	$params{readonly} = 1;

	# Hand off to the main ORLite class.
	my $rv = $class->SUPER::import( \%params, $DEBUG ? '-DEBUG' : () );

	# If and only if they update at connect-time, replace the
	# original dbh method with one that syncs the database.
	if ( $params{update} eq 'connect' ) {
		my $code = <<"END_PERL";
package $params{package};

use vars qw{ \$SYNCED };
BEGIN {
	\$SYNCED = 0;
	delete \$$params{package}::{DBH};
}

sub connect {
	my $class = shift;
	
}
END_PERL
	}

	return $rv;
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
