#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use EVE::TextPattern ();





######################################################################
# Main Tests

# Create a search pattern
my $pattern = EVE::TextPattern->new(
	name => 'Kulu',
);
isa_ok( $pattern, 'EVE::TextPattern' );
isa_ok( $pattern, 'Imager::Search::Pattern' );
