#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Test::Script;

use_ok( 'Perl::Dist'                 );
use_ok( 'Perl::Dist::Builder'        );
use_ok( 'Perl::Dist::Inno'           );
use_ok( 'Perl::Dist::Inno::File'     );
use_ok( 'Perl::Dist::Inno::Icon'     );
use_ok( 'Perl::Dist::Inno::Registry' );

script_compiles_ok( 'script/perldist' );
