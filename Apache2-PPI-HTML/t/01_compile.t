#!/usr/bin/perl -w

# Load test the Apache2::PPI::HTML module

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






# Does everything load?
use Test::More 'tests' => 1;

ok( $] >= 5.005, 'Your perl is new enough' );

# use_ok('Apache2::PPI::HTML');

1;
