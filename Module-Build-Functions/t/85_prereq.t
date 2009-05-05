#!/usr/bin/perl

# Test that all our prerequisites are defined in the Makefile.PL.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq 1.036',
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

diag('Takes a few minutes...');
my @modules_skip = (
# Needed only for AUTHOR_TEST tests
       'Perl::Critic::More',
       'Test::HasVersion',
       'Test::MinimumVersion',
       'Test::Perl::Critic',
       'Test::Prereq',
	   'Test::Pod::Coverage',
);

prereq_ok(5.006, 'Check prerequisites', \@modules_skip);

# use File::Copy qw();
# use File::Remove qw();

# File::Copy::move( 't\inc\Module\Install.pm', 'inc\Module\Install.pm' );
# File::Remove::remove( \1, 't\inc' );
