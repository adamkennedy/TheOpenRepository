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
my $dist = Test::Perl::Dist->new_test_class_long(93, '5100', 'Perl::Dist::WiX', 'portable' => 1);

test_run_dist( $dist );

test_verify_files_long(93, '510');

test_verify_portability(93);
