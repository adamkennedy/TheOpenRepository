#!/usr/bin/perl

# Test the recursive feature

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	require lib;
	lib->import( catdir( curdir(), 't', 'modules' ) );
}

use Test::More tests => 5;
use Class::Autouse ();





# Load the T test module recursively
ok( Class::Autouse->autouse_recursive('T'), '->autouse_recursive returns true' );
ok( T->method, 'T is loaded' );
ok( T::A->method, 'T::A is loaded' );
ok( T::B->method, 'T::B is loaded' );
ok( T::B::G->method, 'T::B::G is loaded' );
