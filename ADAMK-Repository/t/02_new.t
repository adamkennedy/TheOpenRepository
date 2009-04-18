#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT} ) {
		plan( tests => 1504 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use Test::NoWarnings;
use ADAMK::Repository;

my $path = $ENV{ADAMK_CHECKOUT};






#####################################################################
# Basic Model Tests

# Create the repository object
my $repository = ADAMK::Repository->new( path => $path );
isa_ok( $repository, 'ADAMK::Repository' );
is( $repository->path, $path, '->path ok' );

# Check distributions
SCOPE: {
	my $expected = 280;
	my @distributions = $repository->distributions;
	ok( scalar(@distributions) >= $expected, 'Found a bunch of distributions' );
	foreach ( 0 .. $expected - 1 ) {
		isa_ok( $distributions[$_], 'ADAMK::Distribution', "Distribution $_" );
	}
}
SCOPE: {
	my $expected = 180;
	my @distributions = $repository->distributions_released;
	ok( scalar(@distributions) >= $expected, 'Found a bunch of distributions_released' );
	foreach ( 0 .. $expected - 1 ) {
		isa_ok( $distributions[$_], 'ADAMK::Distribution', "Distribution $_" );
	}
}
SCOPE: {
	my $expected = 20;
	my @distributions = $repository->distributions_like('Test');
	ok( scalar(@distributions) >= $expected, 'Found a bunch of distributions' );
	foreach ( 0 .. $expected - 1 ) {
		isa_ok( $distributions[$_], 'ADAMK::Distribution', "Distribution $_" );
	}
}
SCOPE: {
	my $expected = 10;
	my @distributions = $repository->distributions_like(qr/^Test-/);
	ok( scalar(@distributions) >= $expected, 'Found a bunch of distributions' );
	ok( scalar(@distributions) <= $expected + 10, 'Found a bunch of distributions' );
	foreach ( 0 .. $expected - 1 ) {
		isa_ok( $distributions[$_], 'ADAMK::Distribution', "Distribution $_" );
	}
}
SCOPE: {
	my $expected = 5;
	my @distributions = $repository->distributions_released(qr/^Test-/);
	ok( scalar(@distributions) >= $expected, 'Found a bunch of distributions' );
	ok( scalar(@distributions) <= $expected + 10, 'Found a bunch of distributions' );
	foreach ( 0 .. $expected - 1 ) {
		isa_ok( $distributions[$_], 'ADAMK::Distribution', "Distribution $_" );
	}
}

# Check releases
SCOPE: {
	my $expected = 998;
	my @releases = $repository->releases;
	ok( scalar(@releases) >= $expected, 'Found a bunch of releases' );
	foreach ( 0 .. $expected - 1 ) {
		isa_ok( $releases[$_], 'ADAMK::Release', "Release $_" );
	}
}
