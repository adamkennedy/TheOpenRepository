#!/usr/bin/perl

# Compile testing for jsan2

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

# Does the module load
require_ok('JSAN::Shell');

# Does the jsan2 script compile
script_compiles( 'script/jsan2' );
