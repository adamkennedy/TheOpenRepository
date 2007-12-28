#!/usr/bin/perl

# Compile testing for PPI::Tester

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'PPI::Tester' );

script_compiles_ok( 'bin/ppitester' );
