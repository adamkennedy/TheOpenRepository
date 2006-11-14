#!/usr/bin/perl -w

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
unless ( $ENV{TEST_P5I_URI} ) {
	plan( skip_all => 'TEST_PIP_URI needed for network tests' );
}

plan( tests => 10 );
use File::Spec::Functions ':ALL';
use Module::Plan::Base;





#####################################################################
# Constructor Testing

# Test with the repository URI
SKIP: {
	my $plan = Module::Plan::Base->read( $ENV{TEST_P5I_URI );
	isa_ok( $plan, 'Module::Plan::Lite' );
}
