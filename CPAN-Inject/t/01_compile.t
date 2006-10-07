#!/usr/bin/perl -w

# Compile testing for CPAN::Inject

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More tests => 2;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'CPAN::Metrics' );

1;
