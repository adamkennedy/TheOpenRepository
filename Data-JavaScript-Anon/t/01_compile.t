#!/usr/bin/perl -w

# Load testing for Data::JavaScript::Anon

# This test only tests that the module compiles.

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		# Setup some things if running outside of a proper Test::Harness
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			'lib',
			);
	}
}

use Test::More tests => 2;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok( 'Data::JavaScript::Anon' );

exit();
