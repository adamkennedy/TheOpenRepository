#!/usr/bin/perl

use strict;
use Aspect;





######################################################################
# Test Class

SCOPE: {
	package Foo;

	sub control {
		return 1;
	}

	sub before {
		return 1;
	}

	sub after {
		return 1;
	}

	sub after_returning {
		return 1;
	}

	sub after_throwing {
		return 1;
	}

	sub around {
		return 1;
	}
}





######################################################################
# Aspect Setup

my $foo = 1;

before {
	$foo++;
} call 'Foo::before';

after {
	$foo++;
} call 'Foo::after';

after {
	$foo++;
} call 'Foo::after_returning' & returning;

after {
	$foo++;
} call 'Foo::after_throwing' & throwing;

around {
	$foo++;
	$_->proceed
} call 'Foo::around';





######################################################################
# Benchmark Execution

use Benchmark ':all';

timethese( 500000, {
	control         => 'Foo::control()',
	before          => 'Foo::before()',
	after           => 'Foo::after()',
	after_returning => 'Foo::after_returning()',
	after_throwing  => 'Foo::after_throwing()',
	around          => 'Foo::around()',
} );
