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
my $dist = Test::Perl::Dist->new_test_class_medium(
	900, '5120', 'Perl::Dist::WiX', 'rt',
	msi => 0,       # Can't have msi => 1 on a medium.
	zip => 1,
	user_agent_cache  => 0,
	gcc_version => 4,
);

test_run_dist( $dist );

test_verify_files_medium(900, '512', 'rt');

test_cleanup(900);

done_testing();
