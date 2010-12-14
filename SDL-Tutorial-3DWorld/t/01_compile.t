#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

use_ok( 'SDL::Tutorial::3DWorld' );

script_compiles_ok( 'script/3dworld' );
