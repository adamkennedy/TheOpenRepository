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





######################################################################
# Parent Session

my $session1 = POE::Session->create(
	inline_states => {
		_start        => \&_start1,
		intermediate  => \&intermediate1,
		is_stopping   => \&is_stopping1,
		pending_event => \&pending_event1,
	},
);
diag("Parent Session ID: " . $session1->ID . "\n");
sub _start1 {
	$poe_kernel->delay_set( intermediate => 0.5 );
	return;
}

sub intermediate1 {
	# Stop the second session via a call
	$poe_kernel->call( 'foo', 'shutdown' );
	$poe_kernel->post( $session1, 'is_stopping' );
}

sub is_stopping1 {
	poe_stopping();
}





######################################################################
# Leaking Session

my $session2 = POE::Session->create(
	inline_states => {
		_start   => \&_start2,
		shutdown => \&shutdown2,
	},
);
diag("Leaked Session ID: " . $session2->ID . "\n");

# The ONLY thing keeping this session alive should be it's alias
sub _start2 {
	$poe_kernel->alias_set('foo');
}

sub shutdown2 {
	# Remove the only thing preventing shutdown
	$poe_kernel->alias_remove('foo');
}





######################################################################
# Test Run

test_out("not ok 1 - POE appears to be stopping cleanly");
test_fail(37);
POE::Kernel->run;
test_err( '# ---'           );
test_err( '# alias: 0'      );
test_err( '# children: 0'   );
test_err( '# current: 1'    );
test_err( '# extra: 0'      );
test_err( '# handles: 0'    );
test_err( '# id: 2'         );
test_err( '# queue:'        );
test_err( '#   distinct: 0' );
test_err( '#   from: 0'     );
test_err( '#   to: 0'       );
test_err( '# refs: 0'       );
test_err( '# signals: 0'    );
test_test("Fails correctly for pending event");
pass( 'POE Stopped' );
