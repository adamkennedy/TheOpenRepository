#!/usr/bin/perl

# Compile testing for Mirror::URI

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.005, "Your perl is new enough" );

use_ok( 'Mirror::URI'  );
use_ok( 'Mirror::YAML' );
