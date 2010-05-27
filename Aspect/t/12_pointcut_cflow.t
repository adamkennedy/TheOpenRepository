#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Aspect;

SCOPE: {
	package My::Foo;

	sub parent1 {
		$_[0]->child;
	}

	sub parent2 {
		$_[0]->child;
	}

	sub child {
		return 1;
	}
}

# Set up the cflow hook
before {
	isa_ok( $_->{parent}, 'Aspect::Point::Before' );
	$_->return_value(2);
} call 'My::Foo::child'
& cflow parent => 'My::Foo::parent2';

is( My::Foo->child,   1, '->child ok'    );
is( My::Foo->parent1, 1, '->parent1 ok' );
is( My::Foo->parent2, 2, '->parent2 ok' );
