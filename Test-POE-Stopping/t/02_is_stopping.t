#!/usr/bin/perl

# Compile testing for Test::POE::Stopping

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::POE::Stopping;
use POE qw{Session};

POE::Session->create(
	inline_states => {
		_start      => \&_start,
		is_stopping => \&is_stopping,
	},
);

POE::Kernel->run;
pass( 'POE Stopped' );





#####################################################################
# Events

sub _start {
	$poe_kernel->delay_set( is_stopping => 0.5 );
	return;
}

sub is_stopping {
	poe_stopping();
}
