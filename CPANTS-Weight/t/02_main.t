#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use CPANTS::Weight ();

my $source = CPANTS::Weight->source;
isa_ok( $source, 'Algorithm::Dependency::Source::DBI' );

1;
