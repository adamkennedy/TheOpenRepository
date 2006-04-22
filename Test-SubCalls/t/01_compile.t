#!/usr/bin/perl -w

# Load test the Test::SubCalls module

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

# Does everything load?
use Test::More tests => 6;
ok( $] >= 5.006, 'Your perl is new enough' );
use_ok( 'Test::SubCalls' );

# Did it import what we expect?
ok( defined(&sub_track),     'Imported sub_track'     );
ok( defined(&sub_calls),     'Imported sub_calls'     );
ok( defined(&sub_reset),     'Imported sub_reset'     );
ok( defined(&sub_reset_all), 'Imported sub_reset_all' );

1;
