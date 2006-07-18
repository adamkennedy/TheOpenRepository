#!/usr/bin/perl -w

# Compile testing for Test::Script

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 3;
use Test::Script;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the script compile
use_ok( 'ADAMK::Debug' );
script_compiles_ok( 'bin/apld' );

exit(0);
