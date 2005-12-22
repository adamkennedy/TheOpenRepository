#!/usr/bin/perl -w

# Test the recursive feature

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
	lib->import( catdir( curdir(), 'modules' ) );
}

use Test::More tests => 5;
use Class::Autouse ();





# Load the T test module recursively
ok( Class::Autouse->autouse_recursive('T'), '->autouse_recursive returns true' );
ok( T->method, 'T is loaded' );
ok( T::A->method, 'T::A is loaded' );
ok( T::B->method, 'T::B is loaded' );
ok( T::B::G->method, 'T::B::G is loaded' );
