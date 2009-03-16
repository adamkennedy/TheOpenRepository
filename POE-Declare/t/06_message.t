#!/usr/bin/perl

# Tests for messages

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 17;
use Test::NoWarnings;
use POE;
use Test::POE::Stopping;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

#BEGIN {
#	$POE::Declare::Meta::DEBUG = 1;
#}





#####################################################################
# Generate the test class

SCOPE: {
	package Foo;

	use strict;
	use POE::Declare;
	use Test::More;

	*order = *main::order;

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
