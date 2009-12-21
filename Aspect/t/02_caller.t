#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use Aspect;

my @CALLER = ();
my $BEFORE = 0;

SCOPE: {
	package Foo;

	sub foo {
		Bar->bar;
	}

	package Bar;

	sub bar {
		@CALLER = (
			[ caller(0) ],
			[ caller(1) ],
		);
		return 'value';
	}
}

# Set up the Aspect
my $aspect = before { $BEFORE++ } call 'Bar::bar';
isa_ok( $aspect, 'Aspect::Advice' );
is( $BEFORE,         0, '$BEFORE is false' );
is( scalar(@CALLER), 0, '@CALLER is empty' );

# Call a method above the wrapped method
my $rv = Foo->foo;
is( $rv, 'value', '->foo is ok' );
is( $BEFORE,         1, '$BEFORE is true' );
is( scalar(@CALLER), 2, '@CALLER is full' );
is( $CALLER[0]->[0], 'Foo',  'First caller is Foo'   );
is( $CALLER[1]->[0], 'main', 'Second caller is main' );
