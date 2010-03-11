#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
$| = 1;

my @MODULES = (
	'Test::Portability::Files 0.05',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

run_tests();
