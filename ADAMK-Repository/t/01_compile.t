#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'ADAMK::Repository' );

script_compiles_ok('script/adamk');
