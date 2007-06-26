#!/usr/bin/perl

# Load testing for CGI::Capture

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

# Check their perl version
ok( $] >= 5.006, 'Your perl is new enough' );

# Does the module load
use_ok('CGI::Capture');
