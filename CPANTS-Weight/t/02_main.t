#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use CPANTS::Weight ();

my $source = CPANTS::Weight->all_source;
isa_ok( $source, 'Algorithm::Dependency::Source::DBI' );

my $weights = CPANTS::Weight->all_weights;
is( ref($weights), 'HASH', '->all_weights returns a HASH' );

my $volatility = CPANTS::Weight->all_volatility;
is( ref($volatility), 'HASH', '->all_volatility returns a HASH' );
