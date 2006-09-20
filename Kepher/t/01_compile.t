#!/usr/bin/perl -w

# Compile Testing for Kepher

use strict;
BEGIN {
	$| = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.006, 'Your perl is new enough' );

require_ok('Kepher');
script_compiles_ok('bin/kepher');

exit(0);
