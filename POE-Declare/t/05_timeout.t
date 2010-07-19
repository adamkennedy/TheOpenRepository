#!/usr/bin/perl

# Validate that _stop fires when expected.
# Tests the use of _start and _restart in different contexts.
# Validates that _finish behaves as expected.

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 16;
# Disabled for now due to POE::Peek::API throwing warnings.
# use Test::NoWarnings;
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

	declare bar => 'Internal';

	sub _start : Event {
		order( 0, 'Fired Foo::_start' );
		$_[0]->SUPER::_start(@_[1..$#_]);

		# Trigger a regular event
		$_[SELF]->post('started');
	}

	sub started : Event {
		order( 3, 'Fired Foo::started' );
		$_[SELF]->timer1_start;
		$_[SELF]->timer1_start;
		$_[SELF]->timer1_restart;
	}

	sub timer1 : Timeout(1) {
		order( 4, 'Fired Foo::timer1' );
		$_[SELF]->timer1_stop;
		$_[SELF]->timer2_stop;
		$_[SELF]->timer2_restart;
		$_[SELF]->call('_finish');
	}

	sub timer2 : Timeout(2) {
		# Should never be called
		die "The timer2 event should never be fired";
	}

	sub _stop : Event {
		order( 6, 'Fired Foo::_stop' );
		$_[0]->SUPER::_stop(@_[1..$#_]);
	}

	sub _alias_set : Event {
		order( 1, 'Fired Foo::_alias_set' );
		$_[0]->SUPER::_alias_set(@_[1..$#_]);
	}

	sub _finish : Event {
		order( 5, 'Fired Foo::_finish' );
		$_[0]->SUPER::_finish(@_[1..$#_]);
	}

	compile;
}

ok( Foo->can('timer1'),         '->timer ok' );
ok( Foo->can('timer1_start'),   '->timer ok' );
ok( Foo->can('timer1_restart'), '->timer ok' );
ok( Foo->can('timer1_stop'),    '->timer ok' );
is_deeply(
	[ Foo->meta->_package_states ],
	[ qw{
		_alias_remove
		_alias_set
		_finish
		_start
		_stop
		started
		timer1
		timer2
	} ],
	'->_package_states ok',
);





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
	order( 2, 'Fired main::_start' );
	$_[KERNEL]->delay_set( timeout => 2 );
}

sub _stop {
	order( 8, 'Fired main::_stop' );
}

sub timeout {
	order( 7, 'Fired main::timeout' );
}

POE::Kernel->run;
