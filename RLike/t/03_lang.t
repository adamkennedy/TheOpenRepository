#!/usr/bin/perl

# Tests for the RLike c() function

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 12;
use Test::NoWarnings;
use RLike;





######################################################################
# Main Tests

# Test the c() concatonation function
SCOPE: {
	my $null = c();
	is( $null, undef, 'c() ok' );

	my $one = c(1);
	isa_ok( $one, 'RLike::Vector' );
	is( $one->l, 1, 'c(1) l' );

	my $two = c(1, 2);
	isa_ok( $two, 'RLike::Vector' );
	is( $two->l, 2, 'c(1,2) l' );

	my $five = c($two, 3, $two);
	isa_ok( $five, 'RLike::Vector' );
	is( $five->l, 5, 'c( two, 3, two ) l' );
}

# Test the length() function
SCOPE: {
	is_deeply(
		length( c(1) ),
		c(1),
		'length(c(1)) ok',
	);
	is_deeply(
		length( c(1,2) ),
		c(2),
		'length(c(1,2)) ok',
	);
}

# Test the sum() function
SCOPE: {
	is_deeply(
		sum( c(1) ),
		c(1),
		'sum(c(1)) ok',
	);
	is_deeply(
		sum( c(1,2) ),
		c(3),
		'sum(c(1,2)) ok',
	);
}
