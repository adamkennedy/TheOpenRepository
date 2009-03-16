#!/usr/bin/perl

# Tests for messages

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;
use POE;
use Test::POE::Stopping;

#BEGIN {
#	$POE::Declare::Meta::DEBUG = 1;
#}





#####################################################################
# Generate the test class

SCOPE: {
	package Foo;

	use POE::Declare;

	declare bar      => 'Internal';
	declare EventOne => 'Message';

	compile;
}





#####################################################################
# Tests

# Start the test session
my $foo = Foo->new(
	EventOne => \&eventone,
);
isa_ok( $foo, 'Foo' );
