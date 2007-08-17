#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.005, 'Perl version is new enough' );

SKIP: {
	unless ( $ENV{AUTOMATED_TESTING} ) {
		skip("AUTOMATED_TESTING is not enabled", 1);
	}
	use_ok( 't::lib::SQLite::Temp' );
	use_ok( 'Algorithm::Dependency::Source::DBI' );
}
