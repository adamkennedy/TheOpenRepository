#!/usr/bin/perl

# Tests for messages

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 3;
use Test::NoWarnings;
use POE;
use Test::POE::Stopping;

BEGIN {
	$POE::Declare::Meta::DEBUG = 1;
}

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( ++$order, $position, "$message ($position)" );
}





#####################################################################
# Generate the test classes

SCOPE: {
	package My::Test1;

	use Test::More;
	use POE::Declare;

	declare EventOne => 'Message';
	declare EventTwo => 'Message';
	declare child    => 'Internal';

	sub _start : Event {
		$_[0]->SUPER::_start(@_[1..$#_]);
		$_[SELF]->post('startup');
	}

	sub startup : Event {
		my $test = 'foo';
		$self->{child} = My::Test2->new(
			Echo1 => $self->postback('message1'),
			Echo2 => $self->callback('message2'),
			Echo3 => $self->lookback('message3'),
		);
	}

	sub message1 : Event {
		
	}

	compile;
}

SCOPE: {

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
