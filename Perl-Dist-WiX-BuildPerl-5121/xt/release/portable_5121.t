#!/usr/bin/perl

use strict;
use warnings;
use English qw(-no_match_vars);
BEGIN {
	$OUTPUT_AUTOFLUSH  = 1;
}

use Test::Perl::Dist 0.300;

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_long(
	902, '5121', 'Perl::Dist::WiX', 'xt/release',
	portable => 1,
	user_agent_cache  => 0,
);

test_run_dist( $dist );

test_verify_files_long(902, '510', 'rt');

test_verify_portability(902, $dist->output_base_filename(), 'xt/release');

test_cleanup(902);

done_testing();

