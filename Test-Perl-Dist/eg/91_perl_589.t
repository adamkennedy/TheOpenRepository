#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Perl::Dist;

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_medium(91, '589', 'Perl::Dist::WiX');
isa_ok( $dist, 'Perl::Dist::WiX' );

test_run_dist( $dist );

test_verify_files_medium(91, '58');