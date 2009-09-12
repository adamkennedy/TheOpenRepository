#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::Perl::Dist;

#####################################################################
# Complete Generation Run

# Throw information on the testing module up.
diag("Testing with Test::Perl::Dist $Test::Perl::Dist::VERSION");

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_short(
	500, '589', 'Perl::Dist::WiX',
);

# Check useragent method
my $ua = $dist->user_agent;
isa_ok( $ua, 'LWP::UserAgent' );

test_run_dist( $dist );

test_verify_files_short(500, '58');

done_testing(1);


