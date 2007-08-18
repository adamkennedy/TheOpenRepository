#!/usr/bin/perl

# Compile testing for pler

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the script compile
use_ok( 'pler' );
script_compiles_ok( 'script/pler' );

exit(0);
