#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Test::Script;

use File::Spec::Functions ':ALL';
use lib catdir( 't', 'lib' );

ok( $] >= 5.005, 'Perl version is new enough' );
use_ok( 'TinyAuth'     );
use_ok( 'My::TinyAuth' );
script_compiles_ok( 'script/tinyauth' );
