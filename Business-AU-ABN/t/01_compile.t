#!/usr/bin/perl

# Compile testing for Business::AU::ABN

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, "Your perl version is new enough" );

use_ok( 'Business::AU::ABN' );
