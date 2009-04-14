#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT}) {
		plan( tests => 12 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use ADAMK::Repository;

my $path = $ENV{ADAMK_CHECKOUT};





#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new(
	path => $path,
);
isa_ok( $repository, 'ADAMK::Repository' );





#####################################################################
# Find the current version of a release

my $release = $repository->release_latest('Config-Tiny');
isa_ok( $release, 'ADAMK::Release' );
ok( -d $release->directory, '->directory ok' );
is( $release->distname, 'Config-Tiny', '->distribution ok' );
is( $release->file, 'Config-Tiny-2.12.tar.gz', '->file ok' );
ok( -f $release->path, "->path exists at " . $release->path );
isa_ok( $release->repository, 'ADAMK::Repository' );
is( $release->version, '2.12', '->version ok' );

# Extract it for examination
my $extract = $release->extract( CLEANUP => 1 );
ok( -d $extract, '->extract ok' );
is( $extract, $release->extracted, '->extracted ok' );

# Run the Araxis tarball comparison
SKIP: {
	unless ( -f ADAMK::Repository->araxis_compare_bin ) {
		skip("Cannot find Araxis Merge to test", 1);
	}
	unless ( $ENV{TEST_ARAXIS} ) {
		skip("Not testing Araxis Merge", 1);
	}
	ok(
		$repository->compare_tarball_latest('Config-Tiny'),
		'->compare_tarball_latest ok',
	);
}

# Run the Araxis export comparison
SKIP: {
	unless ( -f ADAMK::Repository->araxis_compare_bin ) {
		skip("Cannot find Araxis Merge to test", 1);
	}
	unless ( $ENV{TEST_ARAXIS} ) {
		skip("Not testing Araxis Merge", 1);
	}
	ok(
		$repository->compare_export_latest('Config-Tiny'),
		'->compare_export_latest ok',
	);
}
