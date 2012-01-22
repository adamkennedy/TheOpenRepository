#!/usr/bin/perl

# Tests for the RLike c() function

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 8;
use Test::NoWarnings;
use RLike;





######################################################################
# Main Tests

SCOPE: {
	my $null = c();
	is( $null, undef, 'c() ok' );

	my $one = c(1);
	isa_ok( $one, 'RLike::Vector' );
	is( $one->length, 1, 'c(1) ok' );

	my $two = c(1, 2);
	isa_ok( $two, 'RLike::Vector' );
	is( $two->length, 2, 'c(1,2) ok' );

	my $five = c($two, 3, $two);
	isa_ok( $five, 'RLike::Vector' );
	is( $five->length, 5, 'c( two, 3, two ) ok' );
}
