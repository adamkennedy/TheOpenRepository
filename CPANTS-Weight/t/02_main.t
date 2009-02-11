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

my @weighty_100 = CPANTS::Weight->weighty_100;
is( scalar(@weighty_100), 100, '->weighty_100 returns 100 names' );
foreach ( 0 .. 99 ) {
	ok( length($weighty_100[$_]), "Element $_ is a string ($weighty_100[$_])" );
}

my @volatile_100 = CPANTS::Weight->volatile_100;
is( scalar(@volatile_100), 100, '->volatile_100 returns 100 names' );
foreach ( 0 .. 99 ) {
	ok( length($volatile_100[$_]), "Element $_ is a string ($volatile_100[$_])" );
}

1;
