#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 205;
use CPANTS::Weight ();

my $source = CPANTS::Weight->all_source;
isa_ok( $source, 'Algorithm::Dependency::Source::DBI' );

my $weights = CPANTS::Weight->all_weights;
is( ref($weights), 'HASH', '->all_weights returns a HASH' );

my $volatility = CPANTS::Weight->all_volatility;
is( ref($volatility), 'HASH', '->all_volatility returns a HASH' );

my @heavy_100 = CPANTS::Weight->heavy_100;
is( scalar(@heavy_100), 100, '->heavy_100 returns 100 names' );
foreach ( 0 .. 99 ) {
	isa_ok( $heavy_100[$_]->[0], 'ORDB::CPANTS::Dist' );
}

my @volatile_100 = CPANTS::Weight->volatile_100;
is( scalar(@volatile_100), 100, '->volatile_100 returns 100 names' );
foreach ( 0 .. 99 ) {
	isa_ok( $volatile_100[$_]->[0], 'ORDB::CPANTS::Dist' );
}

1;
