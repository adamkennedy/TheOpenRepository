#!/usr/bin/perl

# Test that modules pass perlcritic and perltidy.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Perl::Critic::More',
	'Test::Perl::Critic',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "require $MODULE"; # Has to be require because we pass options to import.
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

use File::Spec::Functions qw(catfile catdir);

my $rcfile = catfile( 't', 'settings', 'perlcritic.txt' );
Test::Perl::Critic->import( -profile => $rcfile, -severity => 1 );

# I only want to criticize my own modules, not the module patches to the differing perls...
if (-d catdir('blib', 'lib')) {
    all_critic_ok(catdir('blib', 'lib', 'Perl'));
} else {
    all_critic_ok();
}