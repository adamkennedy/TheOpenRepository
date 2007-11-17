#!/usr/bin/perl -w

# Load test the Template::Plugin::StringTree module and do some super-basic tests

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}





# Does everything load?
use Test::More 'tests' => 3;
BEGIN {
	ok( $] >= 5.005, 'Your perl is new enough' );
}

use_ok( 'Template::Plugin::StringTree' );
use_ok( 'Template::Plugin::StringTree::Node' );

1;
