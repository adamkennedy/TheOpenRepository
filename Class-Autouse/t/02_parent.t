#!/usr/bin/perl -w

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

use Test::More tests => 2;
use Class::Autouse qw{:devel};
use Class::Autouse::Parent;

# Test the loading of children
use_ok( 'A' );
ok( $A::B::loaded, 'Parent class loads child class OK' );
$A::B::loaded ? 1 : 0 # Shut a warning up

