#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::Perl::Dist;

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_medium(
	900, '5115', 'Perl::Dist::WiX', 
	msi => 1,
	zip => 1,
);

test_run_dist( $dist );

test_verify_files_medium(900, '511');

done_testing();
