#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT}) {
	plan( tests => 7 );
} else {
	plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
}

use ADAMK::Repository;

my $root = $ENV{ADAMK_CHECKOUT};





#####################################################################
# Constructor

my $repository = ADAMK::Repository->new(
	root    => $root,
	preload => 1,
);
isa_ok( $repository, 'ADAMK::Repository' );
is( ref($repository->{distributions}), 'ARRAY', 'Preloaded distributions ok' );
is( ref($repository->{releases}),      'ARRAY', 'Preloaded releases ok'      );

# Check the number of distributions of various types
my $dists    = scalar($repository->distributions);
my $released = scalar($repository->distributions_released);
ok(
	$dists > 275,
	'Found 275+ distributions as expected',
);
ok(
	($dists - $released) > 90,
	'Found 90 less released distributions',
);





#####################################################################
# Fetch all releases for a distribution

my @releases = $repository->distribution('Config-Tiny')->releases;
ok( 5 < scalar(@releases),   'Got correct number of Config::Tiny releases' );
ok( scalar(@releases) < 100, 'Got correct number of Config::Tiny releases' );
