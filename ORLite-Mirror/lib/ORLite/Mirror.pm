package ORLite::Mirror;

use 5.006;
use strict;
use Carp                   ();
use File::Spec             ();
use File::Path             ();
use File::Remove           ();
use File::HomeDir          ();
use LWP::UserAgent         ();
use Params::Util           qw{ _STRING _HASH };
use IO::Uncompress::Gunzip ();
use ORLite                 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.02';
	@ISA     = qw{ ORLite };
}





#####################################################################
# Code Generation

sub import {
	my $class = ref($_[0]) || $_[0];

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

	# Determine the mirror database path
	my $file = $params{package} . '.sqlite';
	$file =~ s/::/-/g;

	# Create the directory
	my $dir = File::Spec->catdir(
		File::HomeDir->my_data,
		'Perl', 'ORLite-Mirror'
	);
	unless ( -e $dir ) {
		File::Path::mkpath( $dir, { verbose => 0 } );
	}

	# Create the default useragent
	my $path      = File::Spec->catfile( $dir, $file );
	my $useragent = delete $params{useragent};
	unless ( $useragent ) {
		my $version = $params{package}->VERSION || 0;
		$useragent = LWP::UserAgent->new(
			timeout => 30,
			agent   => "$params{package}/$version",
		);
	}

	# Attempt to update the mirror
	my $url      = delete $params{url};
	if ( $url =~ /\.gz$/ ) {
		$path .= '.gz';
	}
	my $response = $useragent->mirror( $url => $path );
	unless ( $response->is_success ) {
		Carp::croak("Error: Failed to fetch $url");
	}

	# Decompress if needed
	my $zipped = $path;
	if ( $path =~ /\.gz$/ ) {
		$path =~ s/\.gz$//;
		IO::Uncompress::Gunzip::gunzip(
			$zipped    => $path,
			BinModeOut => 1,
		) or Carp::croak("Failed to unzip $zipped");
	}

	# Mirrored databases are always readonly.
	$params{file}     = $path;
	$params{readonly} = 1;

	# Hand off to the main ORLite class.
	$class->SUPER::import( \%params );
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

=head1 DESCRIPTION

L<ORLite> provides a readonly ORM API when it loads a readonly SQLite
database from your local system.

By combining this capability with L<LWP>, L<ORLite::Mirror> goes one step
better and allows you to load a SQLite database from any arbitrary URI in
readonly form as well.

As demonstrated in the synopsis above, you using L<ORLite::Mirror> in the
same way, but provide a URL instead of a file name.

If the URL explicitly ends with a '.gz' then L<ORLite::Mirror> will
decompress the file before loading it.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Mirror>

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
