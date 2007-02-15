#!/usr/bin/perl

# Formal testing for Test::ClassAPI

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

# Check their perl version
BEGIN {
	ok( $] >= 5.005, "Your perl is new enough" );
}

# Does the module load
use_ok( 'Test::ClassAPI' );

exit(0);
