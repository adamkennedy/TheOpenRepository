#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	require lib;
	lib->import( catdir( curdir(), 't', 'modules' ) );
}

use Test::More tests => 2;
use Class::Autouse qw{:devel};
use Class::Autouse::Parent;

# Test the loading of children
use_ok( 'A' );
ok( $A::B::loaded, 'Parent class loads child class OK' );
$A::B::loaded ? 1 : 0 # Shut a warning up
