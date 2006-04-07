#!/usr/bin/perl -wl

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

use Test::More tests => 1;
use Scalar::Util 'refaddr';

use Class::Autouse;
Class::Autouse->autouse('baseB');

ok( baseB->isa('baseA'), 'isa() triggers autouse' );

