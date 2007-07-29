#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'Imager::Search' );
use_ok( 'Imager::Search::RRGGBB' );
