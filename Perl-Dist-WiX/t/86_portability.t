#!/usr/bin/perl

# Test that our MANIFEST describes the distribution

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Portability::Files 0.05',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

plan( skip_all => "Test::Portability::Files is buggy at the moment." );
exit(0);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

options(
	test_one_dot => 0, # Will fail test_one_dot deliberately.
	test_amiga_length => 1,
	test_ansi_chars => 1,
	test_case => 1,
	test_dos_length => 0,
	test_mac_length => 1,
	test_space => 1,
	test_special_chars => 1,
	test_symlink => 1,
	test_vms_length => 1,
);
run_tests();
