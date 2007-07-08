#!/usr/bin/perl 

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Test::Script;

ok( $] >= 5.005, 'Perl version is newer than 5.005' );

use_ok( 'Module::Plan::Base'    );
use_ok( 'Module::Plan::Lite'    );
use_ok( 'Module::Plan::Archive' );
use_ok( 'Module::P5Z'           );
use_ok( 'pip'                   );

script_compiles_ok( 'script/pip' );

# Test the test library
use_ok( 't::lib::Test' );
