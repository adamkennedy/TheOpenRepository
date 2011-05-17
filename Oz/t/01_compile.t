#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

ok( $] >= 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'Oz'           );
use_ok( 'Oz::Script'   );
use_ok( 'Oz::Compiler' );
