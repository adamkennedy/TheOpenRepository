#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'POE' );
use_ok( 'PITA::POE::SupportServer' );
