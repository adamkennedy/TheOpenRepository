#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	plan( tests => 4 );
}

use File::Spec::Functions ':ALL';
use t::lib::Bootstrap ();
use URI::file             ();

sub cpan_uri {
	my $path  = 'C:\\devel\\minicpan';
	ok( -d $path, 'Found CPAN directory' );
	ok( -d catdir( $path, 'authors', 'id' ), 'Found id subdirectory' );
	return URI::file->new($path . '\\');
}





#####################################################################
# Run the install

my $dist = t::lib::Bootstrap->new(
	cpan_uri => cpan_uri(),
);
isa_ok( $dist, 'Perl::Dist::Bootstrap' );
diag("This test may take up to an hour...");
ok( $dist->run, '->run ok' );

1;
