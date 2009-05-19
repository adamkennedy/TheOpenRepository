#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.006, 'Perl version ok' );

use_ok( 'Aspect::Library::Profiler' );
