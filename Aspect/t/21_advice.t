#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 19;
use Aspect;





######################################################################
# Test Package

# Needs to be first, due to prototype usage

SCOPE: {
	package My::Foo;

	use strict;
	use warnings;
	use Carp;

	sub new { bless {}, shift }
	sub foo { 'foo'           }
	sub bar { shift->foo      }
	sub inc { $_[1] + 1       }

	sub main::advice_tests_func_no_proto { shift }

	sub main::advice_tests_func_with_proto ($) { shift }
}

my $subject = My::Foo->new;

is( $subject->foo, 'foo', 'foo not yet installed' );
is( $subject->inc(2), 3, 'inc not yet installed' );

SCOPE: {
	my @advice;
	push @advice, before {
		shift->return_value('bar')
	} call "My::Foo::foo";
	is( $subject->foo, 'bar', 'before changing return_value' );

	push @advice, after {
		my $c = shift;
		$c->return_value($c->self)
	} call sub {
		shift eq "My::Foo::foo"
	};
	is( $subject->foo, $subject, 'after changing return_value' );

	push @advice, before {
		my $p = shift->params;
		splice @$p, 1, 1, $p->[1] + 1;
	} call qr/My::Foo::inc/;
	is( $subject->inc(2), 4, 'before advice changing params' );

	push @advice, after {
		my $c = shift;
		$c->return_value($c->return_value + 1);
	} call "My::Foo::inc";
	is( $subject->inc(2), 5, 'before and after together' );
}

SCOPE: {
	my @advice;
	push @advice, after {
		my $c = shift;
		$c->return_value($c->params->[1]);
	} call "My::Foo::foo";
	is( $subject->foo('baz'), 'baz', 'after advice accessing params' );

	push @advice, before {
		my $p = shift->params;
		splice @$p, 1, 1, $p->[1] x 2
	} call "My::Foo::foo";
	is( $subject->foo('baz'), 'bazbaz', 'same but with a before advice' );
}

is( $subject->foo, 'foo', 'foo uninstalled' );
is( $subject->inc(3), 4, 'inc uninstalled' );

is( $subject->bar, 'foo', 'bar cflow not yet installed' );
is( $subject->foo, 'foo', 'foo cflow not yet installed' );
SCOPE: {
	my $advice = before {
		my $c = shift;
		$c->return_value($c->my_key->self);
	} call "My::Foo::foo"
	& cflow my_key => "My::Foo::bar";
	is( $subject->bar, $subject, 'foo cflow installed' );
	is( $subject->foo, 'foo', 'foo called out of the cflow' );
}

is( $subject->bar, 'foo', 'bar cflow uninstalled' );
is( $subject->foo, 'foo', 'foo cflow uninstalled' );

SCOPE: {
	my $advice = before {
		shift->return_value('wrapped')
	} call 'main::advice_tests_func_no_proto';
	is( main::advice_tests_func_no_proto('foo'), 'wrapped' );
}

SCOPE: {
	my $advice = before {
		shift->return_value('wrapped');
	} call 'main::advice_tests_func_with_proto';
	is( main::advice_tests_func_with_proto('foo'), 'wrapped', 'can wrap' );
	eval 'main::advice_tests_func_with_proto(1, 2)';
	like( $@, qr/Too many arguments/, 'prototypes are obeyed' );
}





