#!/usr/bin/perl

# Tests that Time::Tiny compiles ok

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.004, "Your perl is new enough" );

use_ok( 'Time::Tiny' );
