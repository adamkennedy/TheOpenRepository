#!/usr/bin/perl

# Load testing for File::LocalizeNewlines

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('File::LocalizeNewlines');

script_compiles_ok( 'bin/localizenewlines' );
