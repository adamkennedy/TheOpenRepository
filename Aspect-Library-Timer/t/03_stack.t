#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Aspect;

# Set up the aspect
my @TIMING = ();

aspect( 'TimerStack',
	zones => {
		foo => call 'Foo::foo',
		bar => call 'Foo::bar',
	},
	handler => sub {
		push @TIMING, [ @_ ];
	},
);

Foo::bar();
Foo::foo();

is( scalar(@TIMING), 2, 'Two timing hooks fired' );
is( $TIMING[0]->[0], 'bar', 'First call starts in zone bar' );
is( $TIMING[1]->[0], 'foo', 'Second call starts in zone foo' );
is( ref($TIMING[0]->[1]), 'ARRAY', 'Second param is an ARRAY' );
is( ref($TIMING[0]->[2]), 'ARRAY', 'Third param is an ARRAY' );
is( ref($TIMING[0]->[3]), 'HASH',  'Fourth param is a HASH' );
is( keys(%{$TIMING[0]->[3]}), 1, 'First entry has a single key' );
is( keys(%{$TIMING[1]->[3]}), 2, 'Second entry has two keys' );

package Foo;

sub foo {
	bar();
}

sub bar {
	sleep 1;
}
