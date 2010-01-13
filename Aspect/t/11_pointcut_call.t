#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use Test::NoWarnings;
use Aspect;

my $good = 'SomePackage::some_method';
my $bad  = 'SomePackage::no_method';

pointcut_ok( string => 'SomePackage::some_method' );
pointcut_ok( re     => qr/some_method/            );
pointcut_ok( code   => sub { shift eq $good }     );

sub pointcut_ok {
	my $type  = shift;
	my $subject = Aspect::Pointcut::Call->new(shift);
	ok(   $subject->match_define($good), "$type match"    );
	ok( ! $subject->match_define($bad),  "$type no match" );
}





######################################################################
# Overloading Tests

# Pointcut currying code will need to do boolean context checks on
# pointcuts, as will some user code.
# Validate we can actually be used in boolean context (and provide an
# entry point to examine where this overloads to in the debugger).
my $pointcut = call 'Foo::bar';
isa_ok( $pointcut, 'Aspect::Pointcut::Call' );
ok( $pointcut, 'Pointcut is usable in boolean context' );

# Test that negation creates a not pointcut
isa_ok( ! $pointcut, 'Aspect::Pointcut::Not' );





######################################################################
# Regresion: Validate that the "not call and call" pattern works.

# The following package has two methods.
# A pointcut that defines "Not one and any method" should match two but
# not match one. And this rule should apply BOTH to the match_all
# define-time rule AND for the match_run runtime rule.
SCOPE: {
	package One;

	sub one { }

	sub two { }
}

my $not_call_and_call = ! call('One::one') & call(qr/^One::/);
isa_ok( $not_call_and_call, 'Aspect::Pointcut::And' );

# Does match_all find only the second method?
is_deeply(
	[ $not_call_and_call->match_all ],
	[ 'One::two' ],
	'->match_all works as expected',
);

# Create the runtime-curried pointcut
my $curried = $not_call_and_call->curry_run;
is( $curried, undef, 'A call-only pointcut curries away to nothing' );
