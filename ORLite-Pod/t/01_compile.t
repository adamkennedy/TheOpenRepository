#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.006, 'Perl version is new enough' );

require_ok( 'ORLite::Pod' );
script_compiles_ok( 'script/orlite2pod' );
