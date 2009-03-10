#!/usr/bin/perl

# Validate that _stop fires when expected

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 10;
use Test::NoWarnings;
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
		is( $order++, 3, 'Fired Foo::say (3)' );
	}

	sub _stop : Event {
		is( $order++, 6, 'Fired Foo::_stop (6)' );
		$_[0]->SUPER::_stop(@_[1..$#_]);
	}

	sub _alias_set : Event {
		is( $order++, 1, 'Fired Foo::_alias_set (1)' );
		$_[0]->SUPER::_alias_set(@_[1..$#_]);
	}

	sub _alias_remove : Event {
		is( $order++, -1, 'Fired Foo::_alias_remove (-1)' );
		$_[0]->SUPER::_alias_remove(@_[1..$#_]);
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
	is( $order++, 2, 'Fired main::_start (2)' );
	$_[KERNEL]->delay_set( timeout => 0.5 );
}

sub _stop {
	is( $order++, 5, 'Fired main::_stop (5)' );
}

sub timeout {
	is( $order++, 4, 'Fired main::timeout (4)' );
}

POE::Kernel->run;
