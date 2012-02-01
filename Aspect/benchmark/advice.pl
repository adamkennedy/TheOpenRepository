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

	sub around {
		return 1;
	}
}





######################################################################
# Aspect Setup

before {
	1;
} call 'Foo::before';

after {
	1;
} call 'Foo::after';

around {
	1;
} call 'Foo::around';





######################################################################
# Benchmark Execution

