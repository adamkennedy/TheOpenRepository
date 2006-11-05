#!/usr/bin/perl -w

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Test::Script;

ok( $] >= 5.005, 'Perl version is newer than 5.005' );

use_ok( 'Module::Plan::Base' );
use_ok( 'Module::Plan::Lite' );
script_compiles_ok( 'bin/pip' );
