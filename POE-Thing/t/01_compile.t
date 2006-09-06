#!/usr/bin/perl -w

# Compile testing for asa

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, "Your perl is new enough" );
require_ok('POE::Thing');

exit(0);
