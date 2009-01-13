#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.006, 'Perl version is new enough' );

require_ok( 'ORLite::Pod' );
