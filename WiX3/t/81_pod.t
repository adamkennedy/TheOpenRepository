#!/usr/bin/perl -T

# Test that modules pass perlcritic and perltidy.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
    'Test::Pod 1.40',
	'Pod::Simple 3.08',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

all_pod_files_ok();
