#!/usr/bin/perl

# Compile testing

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.005, 'Perl version is new enough' );

require_ok( 'ADAMK::Starter' );
script_compiles_ok( 'bin/adamk-starter' );

