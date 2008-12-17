#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
if ( $ENV{ADAMK_CHECKOUT} ) {
	plan( tests => 10 );
} else {
	plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined' );
}

use ADAMK::Repository;





#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new(
	root    => $ENV{ADAMK_CHECKOUT},
);
isa_ok( $repository, 'ADAMK::Repository' );





#####################################################################
# Find the current version of a release

my $release = $repository->release_latest('Config-Tiny');
isa_ok( $release, 'ADAMK::Release' );
is( $release->directory, 'releases', '->directory ok' );
is( $release->distribution, 'Config-Tiny', '->distribution ok' );
is( $release->file, 'Config-Tiny-2.12.tar.gz', '->file ok' );
ok( -f $release->path, "->path exists at " . $release->path );
isa_ok( $release->repository, 'ADAMK::Repository' );
is( $release->version, '2.12', '->version ok' );

# Extract it for examination
my $extract = $release->extract( CLEANUP => 1 );
ok( -d $extract, '->extract ok' );
is( $extract, $release->extracted, '->extracted ok' );

# Run the Araxis comparison
$repository->compare_tarball_latest('Config-Tiny');
