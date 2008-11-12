#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
if ( $ENV{ADAMK_CHECKOUT} ) {
	plan( tests => 1001 );
} else {
	plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined' );
}

use ADAMK::Repository;

my $root = $ENV{ADAMK_CHECKOUT};






#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new( root => $root );
isa_ok( $repository, 'ADAMK::Repository' );
is( $repository->root, $root, '->root ok' );





#####################################################################
# Release Methods

my $expected = 998;
my @releases = $repository->releases;
ok( scalar(@releases) >= $expected, 'Found a bunch of releases' );
foreach ( 0 .. $expected - 1 ) {
	isa_ok( $releases[$_], 'ADAMK::Release', "Release $_" );
}
