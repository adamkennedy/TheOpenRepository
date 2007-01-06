#!/usr/bin/perl -w

# Load testing for Object::Signature

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok('Object::Signature'      );
use_ok('Object::Signature::File');

exit(0);
