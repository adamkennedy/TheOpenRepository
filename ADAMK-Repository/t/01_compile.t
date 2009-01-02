#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::Script;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'ADAMK::Repository'       );
use_ok( 'ADAMK::Repository::Util' );
use_ok( 'ADAMK::Distribution'     );
use_ok( 'ADAMK::Release'          );

script_compiles_ok('script/adamk');
