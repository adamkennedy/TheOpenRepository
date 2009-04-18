#!/usr/bin/perl

# Tests for the ADAMK::Role::Make role

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT} ) {
		plan( tests => 7 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use ADAMK::Repository ();

my $repository = ADAMK::Repository->new(
	path => $ENV{ADAMK_CHECKOUT},
);
isa_ok( $repository, 'ADAMK::Repository' );





#####################################################################
# Make Tests

my @versions = (
	'Config-Tiny'      => undef,
	'Class-Default'    => 0,
	'ADAMK-Repository' => '0.83',
);
while ( @versions ) {
	my $name     = shift @versions;
	my $expected = shift @versions;
	my $distribution = $repository->distribution($name);
	isa_ok( $distribution, 'ADAMK::Distribution' );
	my $version = $distribution->mi;
	is( $version, $expected, "Version for $name matches expected value" );
}
