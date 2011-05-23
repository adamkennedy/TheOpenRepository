#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 19;
use Test::NoWarnings;
use Test::Exception;
use Aspect;





######################################################################
# Test the regexp exception case

my $x = after {
	$_->exception('three');
} call qr/^Foo::/
& throwing qr/two/;
is( $x->installed, 5, 'Installed to 5 functions' );

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

is( Foo::five(), 'five', 'Foo::five() returns without throwing' );





######################################################################
# Test the object exception case

my $y = after {
	$_->exception('three');
} call qr/^Bar::/
& throwing 'Exception1';
is( $y->installed, 5, 'Installed to 5 functions' );

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

is( Bar::five(), 'five', 'Foo::five() returns without throwing' );





######################################################################
# Test the null throwing case

my $z = after {
	$_->exception('three');
} call qr/^Baz::/
& throwing;
is( $z->installed, 5, 'Installed to 5 functions' );

throws_ok(
	sub { Baz::one() },
	qr/^three/,
	'Hooked negative string exception is in the pointcut',
);

throws_ok(
	sub { Baz::two() },
	qr/^three/,
	'Hooked negative string exception is in the pointcut',
);

throws_ok(
	sub { Baz::three() },
	qr/^three/,
	'Hooked positive object exception is in the pointcut',
);

throws_ok(
	sub { Baz::four() },
	qr/^three/,
	'Hooked negative object exception is in the pointcut',
);

is( Baz::five(), 'five', 'Foo::five() returns without throwing' );





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

sub five {
	return 'five';
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

sub five {
	return 'five';
}

package Baz;

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

sub five {
	return 'five';
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
