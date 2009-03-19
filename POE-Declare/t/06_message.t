#!/usr/bin/perl

# Tests for messages

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 3;
# use Test::NoWarnings;
use POE;
use Test::POE::Stopping;

#BEGIN {
#	$POE::Declare::Meta::DEBUG = 1;
#}





#####################################################################
# Generate the test class

SCOPE: {
	package Foo::Bar;

	use POE::Declare;

	declare bar      => 'Internal';
	declare EventOne => 'Message';
	declare EventTwo => 'Message';

	sub foo : Event {

	}

	compile;
}





#####################################################################
# Tests

# Start the test session
my $foo = Foo::Bar->new(
	EventOne => \&eventone,
	EventTwo => [ 'Foo::Bar.1', 'foo' ],
);
isa_ok( $foo, 'Foo::Bar' );
is( ref($foo->{EventOne}), 'CODE', 'EventOne is a CODE reference' );
is( ref($foo->{EventTwo}), 'CODE', 'EventTwo is a CODE reference' );
