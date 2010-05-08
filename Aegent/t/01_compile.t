#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::NoWarnings;

use_ok( 'Aegent' );

ok( $Aegent::VERSION, 'Loaded Aegent' );
is( $_->VERSION, $Aegent::VERSION, "Loaded matching $_" ) foreach qw{
	Aegent::Class
	Aegent::Object
	Aegent::Attribute
};


