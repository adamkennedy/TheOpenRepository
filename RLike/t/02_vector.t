#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 12;
use Test::NoWarnings;
use RLike::Vector;





######################################################################
# Constructor Test

SCOPE: {
	my $one = RLike::Vector->new(1);
	isa_ok( $one, 'RLike::Vector' );
	is( $one->length, 1, '->length ok' );
	is_deeply( [ $one->list ], [ 1 ], '->list ok' );
}





######################################################################
# Arithmatic Operations

# Addition
SCOPE: {
	my $vector = RLike::Vector->new(1, 2, 3, 4);
	isa_ok( $vector, 'RLike::Vector' );

	is_deeply(
		$vector->add($vector),
		RLike::Vector->new(2, 4, 6, 8),
		'v->add(v) ok',
	);

}

# Subtraction
SCOPE: {
	my $vector = RLike::Vector->new(1, 2, 3, 4);
	isa_ok( $vector, 'RLike::Vector' );

	is_deeply(
		$vector->subtract($vector),
		RLike::Vector->new(0, 0, 0, 0),
		'v->subtract(v) ok',
	);

}

# Multiplication
SCOPE: {
	my $vector = RLike::Vector->new(1, 2, 3, 4);
	isa_ok( $vector, 'RLike::Vector' );

	is_deeply(
		$vector->multiply($vector),
		RLike::Vector->new(1, 4, 9, 16),
		'v->multiple(v) ok',
	);

}

# Division
SCOPE: {
	my $vector = RLike::Vector->new(1, 2, 3, 4);
	isa_ok( $vector, 'RLike::Vector' );

	is_deeply(
		$vector->divide($vector),
		RLike::Vector->new(1, 1, 1, 1),
		'v->divide(v) ok',
	);

}
