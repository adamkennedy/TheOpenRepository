#!perl

use strict;
use warnings;
use Test::More;
$| = 1;

my @MODULES = (
	'Pod::Simple 3.07',
	'Test::Pod 1.26',
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

all_pod_files_ok();

