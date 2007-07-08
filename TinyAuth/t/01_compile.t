#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::Script;

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'TinyAuth'          );
use_ok( 't::lib::Test'      );
use_ok( 't::lib::TinyAuth'  );
use_ok( 'TinyAuth::Install' );

script_compiles_ok( 'script/tinyauth' );
