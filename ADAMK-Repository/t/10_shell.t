#!/usr/bin/perl

# Tests for ADAMK::Shell

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT} ) {
		plan( tests => 2 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use ADAMK::Shell ();

my $shell = new_ok( 'ADAMK::Shell', [
	path => $ENV{ADAMK_CHECKOUT},
] );
isa_ok( $shell->repository, 'ADAMK::Repository' );
