#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

use_ok( 'Perl::Dist'          );
use_ok( 'Perl::Dist::Builder' );

script_compiles_ok( 'script/perldist' );
