#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use Test::Script 1.07;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
	use_ok( 'Perl::Dist::Strawberry::QA' ) or BAIL_OUT('Could not load Perl::Dist::Strawberry::QA.');
}

diag( "Testing Perl::Dist::Strawberry::QA $Perl::Dist::Strawberry::QA::VERSION" );

script_compiles( 'script/strawberry_qa.pl', 'Strawberry QA script compiles' );
