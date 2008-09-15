#!/usr/bin/perl

# Compile testing for jsan2

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
require_ok('JSAN::Shell');

# Does the jsan2 script compile
script_compiles_ok( 'script/jsan2' );
