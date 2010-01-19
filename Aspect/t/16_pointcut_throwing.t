#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use Test::NoWarnings;
use Test::Exception;
use Aspect;





######################################################################
# Test the regexp exception case

after { $_[0]->exception('three') } call qr/^Foo::/ & throwing qr/two/;

throws_ok(
	sub { Foo::one() },
	qr/^one/,
	'Hooked positive string exception is in the pointcut',
);

throws_ok(
	sub { Foo::two() },
	qr/^three/,
	'Hooked negative string exception is not in the pointcut',
);

throws_ok(
	sub { Foo::three() },
	'Exception1',
	'Hooked negative object exception is not in the pointcut',
);

throws_ok(
	sub { Foo::four() },
	'Exception2',
	'Hooked negative object exception is not in the pointcut',
);





######################################################################
# Test the object exception case

after { $_[0]->exception('three') } call qr/^Bar::/ & throwing 'Exception1';

throws_ok(
	sub { Bar::one() },
	qr/^one/,
	'Hooked negative string exception is not in the pointcut',
);

throws_ok(
	sub { Bar::two() },
	qr/^two/,
	'Hooked negative string exception is not in the pointcut',
);

throws_ok(
	sub { Bar::three() },
	qr/^three/,
	'Hooked positive object exception is in the pointcut',
);

throws_ok(
	sub { Bar::four() },
	'Exception2',
	'Hooked negative object exception is not in the pointcut',
);





######################################################################
# Support Classes

package Foo;

sub one {
	die 'one';
}

sub two {
	die 'two';
}

sub three {
	Exception1->throw('one');
}

sub four {
	Exception2->throw('two');
}

package Bar;

sub one {
	die 'one';
}

sub two {
	die 'two';
}

sub three {
	Exception1->throw('one');
}

sub four {
	Exception2->throw('two');
}

package Exception1;

sub throw {
	my $class = shift;
	my $self  = bless [ @_ ], $class;
	die $self;
}

package Exception2;

sub throw {
	my $class = shift;
	my $self  = bless [ @_ ], $class;
	die $self;
}

1;
