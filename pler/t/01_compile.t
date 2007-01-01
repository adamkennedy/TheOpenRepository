#!/usr/bin/perl -w

# Compile testing for Test::Script

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
}

use Test::More tests => 3;
use Test::Script;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the script compile
use_ok( 'Devel::Pler' );
script_compiles_ok( 'bin/pler' );

exit(0);
