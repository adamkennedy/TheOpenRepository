#!/usr/bin/perl -w

# Compile-testing for Test::NeedsDisplay

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 2;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

require_ok( 'Test::NeedsDisplay' );

exit(0);
