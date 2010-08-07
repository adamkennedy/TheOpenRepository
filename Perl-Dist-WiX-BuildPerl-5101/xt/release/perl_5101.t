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
my $dist = Test::Perl::Dist->new_test_class_medium(
	901, '5101', 'Perl::Dist::WiX', 'xt/release',
	msi => 0,
	zip => 1,
	user_agent_cache  => 0,
);

test_run_dist( $dist );

test_verify_files_medium(901, '510', 'xt/release');

test_cleanup(901);

done_testing();
