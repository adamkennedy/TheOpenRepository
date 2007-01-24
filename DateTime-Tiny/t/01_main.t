#!/usr/bin/perl -w

# Tests that DateTime::Tiny compiles

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use DateTime::Tiny;

# Create an object
SCOPE: {
	my $blank = DateTime::Tiny->new;
	isa_ok( $blank, 'DateTime::Tiny' );
}

exit(0);
