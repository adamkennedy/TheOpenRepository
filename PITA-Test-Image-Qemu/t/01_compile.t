#!/usr/bin/perl

# Compile-testing for PITA::Test::Image::Qemu

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'PITA::Test::Image::Qemu' );

exit(0);
