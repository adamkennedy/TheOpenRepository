#!/usr/bin/perl

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.006, 'Your Perl is 5.006 or newer' );
use_ok( 'EVE::Macro::Object' );

1;
