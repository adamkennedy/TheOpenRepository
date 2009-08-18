#!/usr/bin/perl
use Test::More tests => 1;

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	use_ok( 'Crypt::DSA' );
}

diag( "Testing Crypt::DSA $Crypt::DSA::VERSION" );
