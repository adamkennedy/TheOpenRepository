#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.006, 'Perl version is new enough' );

require_ok( 'ORLite' );
require_ok( 't::lib::Test' );
