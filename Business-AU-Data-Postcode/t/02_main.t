#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Business::AU::Data::Postcode;




#####################################################################
# Main Tests

# Test the primary interface
SCOPE: {
	my $parse_csv = Business::AU::Data::Postcode->get;
	isa_ok( $parse_csv, 'Parse::CSV' );
}
SCOPE: {
	my $parse_csv = Business::AU::Data::Postcode->get('Parse::CSV');
	isa_ok( $parse_csv, 'Parse::CSV' );
}
