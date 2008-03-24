#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Win32::Env::Path' );
script_compiles_ok( 'script/win32envpath' );
