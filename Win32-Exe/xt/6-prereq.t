#!/usr/bin/perl

# Test that all our prerequisites are defined in the Makefile.PL.

use strict;
use warnings;
use Test::More;
use File::Path qw();
$| = 1;

my @MODULES = (
	'Test::Prereq 1.036',
	'File::Copy::Recursive 0.38'
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

if (not $ENV{RELEASE_TESTING}) {
	plan( skip_all => "Test::Prereq and Module::Install do not work well together." );
}

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

my @modules_skip = (
# Needed only for AUTHOR_TEST tests
		'Test::More',
		'Test::UseAllModules',
);

File::Copy::Recursive::dircopy( 'inc', 'xt\inc' );

prereq_ok(5.006, 'Check prerequisites', \@modules_skip);

File::Copy::copy( 'xt\inc\Module\Install.pm', 'inc\Module\Install.pm' );
File::Path::rmtree( 'xt\inc', 0, 1 );
