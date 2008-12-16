#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
if ( $ENV{ADAMK_CHECKOUT} ) {
	plan( tests => 5 );
} else {
	plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined' );
}

use ADAMK::Repository;

my $root = $ENV{ADAMK_CHECKOUT};






#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new(
	root    => $root,
	preload => 1,
);
isa_ok( $repository, 'ADAMK::Repository' );
is( ref($repository->{distributions}), 'ARRAY', 'Preloaded distributions ok' );
is( ref($repository->{releases}),      'ARRAY', 'Preloaded releases ok'      );






#####################################################################
# Fetch all distributions for a release

my @releases = $repository->distribution_releases('Config-Tiny');
ok( 5 < scalar(@releases),   'Got correct number of Config::Tiny releases' );
ok( scalar(@releases) < 100, 'Got correct number of Config::Tiny releases' );
