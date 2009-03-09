#!/usr/bin/perl

# Validate that _stop fires when expected

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use POE;
use Test::POE::Stopping;

# Counter for confirming that events fire in the order we expect
my $order = 0;





#####################################################################
# Generate the test class

SCOPE: {
	package Foo;

	use strict;
	use POE::Declare;
	use Test::More;

	declare bar => 'Internal';

	sub _start : Event {
		is( $order++, 0, 'Fired Foo::_start (0)' );
		$_[0]->SUPER::_start(@_[1..$#_]);

		# Trigger a regular event
		my $self = $_[SELF];
		$_[SELF]->post( say => 'Hello World!' );
	}

	sub say : Event {
		is( $order++, 2, 'Fired Foo::say (3)' );
	}

	sub _stop : Event {
		is( $order++, 5, 'Fired Foo::_stop (2)' );
		shift->SUPER::_stop(@_);
	}

	compile;
}





#####################################################################
# Tests

# Start the test session
my $foo = new_ok( Foo => [] );
ok( $foo->spawn, '->spawn ok' );

# Start another session to intentionally
# prevent the kernel shutdown from firing
POE::Session->create(
	inline_states => {
		_start  => \&_start,
		_stop   => \&_stop,
		timeout => \&timeout,
	},
);

sub _start {
	is( $order++, 1, 'Fired main::_start (1)' );
	$_[KERNEL]->delay_set( timeout => 0.5 );
}

sub _stop {
	is( $order++, 4, 'Fired main::_stop (4)' );
}

sub timeout {
	is( $order++, 3, 'Fired main::timeout (3)' );
}

POE::Kernel->run;
