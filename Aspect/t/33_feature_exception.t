#!/usr/bin/perl

# This tests that aspects can be built to fire even when the
# point function throws an exception.

use strict;
use Test::More skip_all => 'Exceptions are not implemented yet';
use Test::More tests => 4;
use Aspect;

# Test package containing methods that work or don't
SCOPE: {
	package Foo;

	sub good {
		return 2;
	}

	sub bad {
		die "Exception";
	}
}

# Set up the aspect
my $fired    = 0;
my $advice   = after { $fired++ } call qr/^Foo::/;

# Call the good function to confirm it works normally
my $rv1 = Foo::good();
is( $rv1, 2, 'Got the expected response' );
is( $fired, 1, 'Aspect fired correctly' );

# Call the bed function to confirm it doesn't work
my $rv2 = eval { Foo::bad() };
is( $rv2, undef, 'Got the expected (lack of a) response' );
is( $fired, 2, 'Aspect fired correctly' );
