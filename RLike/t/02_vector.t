#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 17;
use Test::NoWarnings;
use RLike::Vector;





######################################################################
# Constructor Test

SCOPE: {
	my $one = RLike::Vector->new(1);
	isa_ok( $one, 'RLike::Vector' );
	is( $one->n, 0, '1->n' );
	is( $one->l, 1, '1->l' );
	is_deeply( [ $one->list ], [ 1 ], '1->list ok' );

	my $three = RLike::Vector->new(1, 2, 3);
	isa_ok( $three, 'RLike::Vector' );
	is( $three->n, 2, '3->n' );
	is( $three->l, 3, '3->l' );
	is_deeply( [ $three->list ], [ 1, 2, 3 ], '3->list' );
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
