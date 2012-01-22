#!/usr/bin/perl

# Tests for the RLike command interface

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 20;
use Test::NoWarnings;
use RLike;





######################################################################
# Main Tests

# Test the c() concatonation command
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

# Test the length() command
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

# Test the max() command
SCOPE: {
	is_deeply(
		max( c(1) ),
		c(1),
		'max(c(1)) ok',
	);
	is_deeply(
		max( c(1,2) ),
		c(2),
		'max(c(1,2)) ok',
	);
}

# Test the min() command
SCOPE: {
	is_deeply(
		min( c(1) ),
		c(1),
		'min(c(1)) ok',
	);
	is_deeply(
		min( c(1,2) ),
		c(1),
		'min(c(1,2)) ok',
	);
}

# Test the range() command
SCOPE: {
	is_deeply(
		range( c(1) ),
		c(1,1),
		'range(c(1)) ok',
	);
	is_deeply(
		range( c(1,2) ),
		c(1,2),
		'range(c(1,2)) ok',
	);
}

# Test the sum() command
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

# Test the mean() command
SCOPE: {
	is_deeply(
		mean( c(1) ),
		c(1),
		'mean(c(1)) ok',
	);
	is_deeply(
		mean( c(1,2) ),
		c(1.5),
		'mean(c(1,2)) ok',
	);
}
