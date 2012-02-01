#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Aspect;

# Set up the aspect
my @TIMING = ();

my $foo = call 'Foo::foo' | call 'Foo::baz';
my $bar = call 'Foo::bar';

aspect ZoneTimer => (
	zones => {
		foo => $foo,
		bar => $bar,
	},
	handler => sub {
		push @TIMING, [ @_ ];
	},
);

Foo::baz();
Foo::bar();
Foo::foo();

is( scalar(@TIMING), 3, 'Three timing hooks fired' );
is( $TIMING[0]->[0], 'foo', 'First call starts in zone foo' );
is( $TIMING[1]->[0], 'bar', 'First call starts in zone bar' );
is( $TIMING[2]->[0], 'foo', 'Second call starts in zone foo' );
is( ref($TIMING[0]->[1]), 'ARRAY', 'Second param is an ARRAY' );
is( ref($TIMING[0]->[2]), 'ARRAY', 'Third param is an ARRAY' );
is( ref($TIMING[0]->[3]), 'HASH',  'Fourth param is a HASH' );
is( keys(%{$TIMING[0]->[3]}), 1, 'First entry has a single key' );
is( keys(%{$TIMING[1]->[3]}), 2, 'Second entry has two keys' );
is( keys(%{$TIMING[2]->[3]}), 2, 'Third entry has two keys' );
like(
	$TIMING[0]->[3]->{foo},
	qr/^\d{6,7}$/,
	'Totals appear to be calculated in integer microseconds',
);

package Foo;

sub foo {
	bar();
}

sub bar {
	baz();
}

sub baz {
	sleep 1;
}

