#!perl

# Test that our MANIFEST describes the distribution

use strict;
use warnings;
use Test::More;
$| = 1;

my @MODULES = (
	'Test::DistManifest 1.009',
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

manifest_ok();
