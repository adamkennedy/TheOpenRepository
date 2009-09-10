#!/usr/bin/perl

# Compile testing for Test::POE::Stopping

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Builder::Tester tests => 2;
use Test::More;
use Test::POE::Stopping;

use POE qw{Session};

POE::Session->create(
	inline_states => {
		_start        => \&_start,
		is_stopping   => \&is_stopping,
		pending_alarm => \&pending_alarm,
	},
);

test_out("not ok 1 - POE appears to be stopping cleanly");
test_fail(27);
POE::Kernel->run;
test_err('# ---'       );
test_err('# alias: 0'  );
test_err('# current: 1');
test_err('# extra: 0'  );
test_err('# handles: 0');
test_err('# id: 2'     );
test_err('# queue: 1'  );
test_err('# signals: 0');
test_test("Fails correctly for pending alarm");
pass( 'POE Stopped' );





#####################################################################
# Events

sub _start {
	$poe_kernel->delay_set( is_stopping   => 1 );
	$poe_kernel->delay_set( pending_alarm => 5 );
	return;
}

sub is_stopping {
	poe_stopping();
}

sub pending_alarm {
	die "This should never run";
}
