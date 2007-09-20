#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'Devel::Leak::Module' );

script_compiles_ok( 'script/perlbloat', 'Main script compiles' );