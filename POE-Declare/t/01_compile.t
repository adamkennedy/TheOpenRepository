#!/usr/bin/perl -w

# Compile testing for POE::Declare

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

ok( $] >= 5.005, "Your perl is new enough" );

require_ok('POE::Declare');
require_ok('POE::Declare::Meta::Attribute');
require_ok('POE::Declare::Meta::Internal');

exit(0);
