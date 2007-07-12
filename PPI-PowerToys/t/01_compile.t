#!/usr/bin/perl

# Compile-testing for Perl::PowerToys

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );
use_ok( 'PPI::PowerToys' );
script_compiles_ok( 'script/ppi_version' );

exit(0);
