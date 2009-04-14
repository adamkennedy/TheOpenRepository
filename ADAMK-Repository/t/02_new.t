#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT} ) {
		plan( tests => 1002 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use Test::NoWarnings;
use ADAMK::Repository;

my $path = $ENV{ADAMK_CHECKOUT};






#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new( path => $path );
isa_ok( $repository, 'ADAMK::Repository' );
is( $repository->path, $path, '->path ok' );





#####################################################################
# Release Methods

my $expected = 998;
my @releases = $repository->releases;
ok( scalar(@releases) >= $expected, 'Found a bunch of releases' );
foreach ( 0 .. $expected - 1 ) {
	isa_ok( $releases[$_], 'ADAMK::Release', "Release $_" );
}
