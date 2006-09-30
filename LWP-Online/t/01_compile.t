#!/usr/bin/perl -w

# Compile testing for LWP-Online

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok('LWP::Online');

ok( ! defined &online, 'LWP::Online does not export by default' );

exit(0);
