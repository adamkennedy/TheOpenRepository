#!/usr/bin/perl

# Testing the :skip_all import flag

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';

# This should never run, so we throw an error
use Test::More tests => 1;
ok( 0, 'Failed to properly :skip_all' );
