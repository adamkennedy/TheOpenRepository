#!/usr/bin/perl

# Main testing for Time::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Time::Tiny ();





#####################################################################
# Basic test

SCOPE: {
	my $tiny = Time::Tiny->new(
		hour   => 1,
		minute => 2,
		second => 3,
		);
	isa_ok( $tiny, 'Time::Tiny' );
	is( $tiny->hour,  '1', '->hour ok'   );
	is( $tiny->minute, 2,  '->minute ok' );
	is( $tiny->second, 3,  '->second ok' );
	is( $tiny->as_string, '01:02:03', '->as_string ok' );
	is( "$tiny", '01:02:03', 'Stringification ok' );
	is_deeply(
		Time::Tiny->from_string( $tiny->as_string ),
		$tiny, '->from_string ok' );
}
