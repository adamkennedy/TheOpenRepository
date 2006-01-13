#!/usr/bin/perl -w

# Test interaction with base.pm

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	if ( $ENV{HARNESS_ACTIVE} ) {
		lib->import( catdir( curdir(), 't', 'modules' ) );
	} else {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( 'modules' );
	}
}

use Test::More tests => 4;
use Class::Autouse ();





#####################################################################
# The case where you autouse only the top module should work fine.

use_ok( 'Class::Autouse' => 'baseB' );
is( baseB->dummy, 2, 'Calling method in baseB interacts with baseA correctly' );





#####################################################################
# Autoloading BOTH of them may fail (nope...)

use_ok( 'Class::Autouse' => 'baseC', 'baseD' );
is( baseD->dummy, 3, 'Calling method in baseD interacts with baseC correctly' );

1;
