#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

# Regular expression code proof of concept
my $big   = "#000000#123456#000000#123456#111111#123456#222222#333333#123456#FFFFFF#123456";
my $small = "(?:#123456).{7}(?:#123456)";
my @match = ();
while ( scalar $big =~ /$small/gs ) {
	my $p = $-[0];
	push @match, $p / 7;
	pos $big = $p + 1;
}
is_deeply( \@match, [ 1, 3, 8 ], 'Proof of concept works' );
