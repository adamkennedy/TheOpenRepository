#!/usr/bin/perl -w

# Test specific functions in Devel::Pler

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use pler;

# Can we find the current perl executable ok
ok( perl(), 'Found perl() ok' );
ok( perl,   'Found perl   ok' );
ok( -f perl, 'perl exists'    );

# Can we find the mandated make
ok( make(), 'Found make() ok' );
ok( make,   'Found make   ok' );

exit(0);
