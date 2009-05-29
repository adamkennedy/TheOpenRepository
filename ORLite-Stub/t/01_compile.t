#!/usr/bin/perl

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

use_ok( 'ORLite::Stub' );

script_compiles_ok( 'script/orlite2stub' );
