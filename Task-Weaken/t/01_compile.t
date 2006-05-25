#!/usr/bin/perl -w

# Compile testing

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), 'lib') );
	}
}

use Test::More tests => 2;

# Load-test Task::Weaken (what the hell)
use_ok( 'Task::Weaken' );

# Load Scalar::Util
use_ok( 'Scalar::Util' );
