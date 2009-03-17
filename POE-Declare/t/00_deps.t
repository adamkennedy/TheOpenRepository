#!/usr/bin/perl

# Test that our META.yml dependencies are actually fulfilled

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my $MODULE = 'Parse::CPAN::Meta 0.05';

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing module
eval "use $MODULE";
if ( $@ ) {
	$ENV{RELEASE_TESTING}
	? die( "Failed to load required release-testing module $MODULE" )
	: plan( skip_all => "$MODULE not available for testing" );
}





#####################################################################
# Checks are hand-written for now

my $file = 'META.yml';
my $meta = Parse::CPAN::Meta::LoadFile($file);

hash( $meta->{requires}           );
hash( $meta->{build_requires}     );
hash( $meta->{configure_requires} );

sub hash {
	my $hash = shift or return;
	foreach my $module ( sort keys %$hash ) {
		my $version = $hash->{$module};
		die 'CODE INCOMPLETE';
	}
}
