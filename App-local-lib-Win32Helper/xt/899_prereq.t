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

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

my @modules_skip = (
# Needed only for AUTHOR_TEST tests
		'Perl::Critic::More',
		'Test::HasVersion',
		'Test::MinimumVersion',
		'Test::Perl::Critic',
		'Test::Prereq',
);

prereq_ok(5.008001, 'Check prerequisites', \@modules_skip);

use File::Copy qw();

File::Copy::move( 't\inc\Module\Install.pm', 'inc\Module\Install.pm' );
File::Remove::remove( \1, 't\inc' );
