#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::Perl::Dist 0.300;

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_long(
	902, '5100', 'Perl::Dist::WiX', 'rt',
	user_agent_cache  => 0,
);

test_run_dist( $dist );

test_verify_files_long(902, '510', 'rt');

test_cleanup(902);

done_testing();
