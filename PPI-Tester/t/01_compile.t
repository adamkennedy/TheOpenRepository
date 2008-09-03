#!/usr/bin/perl

# Compile testing for PPI::Tester

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.006, 'Your perl is new enough' );

use_ok( 'PPI::Tester' );

script_compiles_ok( 'script/ppitester' );
