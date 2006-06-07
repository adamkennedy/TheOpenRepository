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

ok( $] >= 5.008005, 'Perl version >= 5.8.5' );

use_ok( 'Task::Weaken' );
