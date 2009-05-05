#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT}) {
		plan( tests => 48 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use ADAMK::Repository;





#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new(
	path    => $ENV{ADAMK_CHECKOUT},
	preload => 1,
);
isa_ok( $repository, 'ADAMK::Repository' );

# Get the test distribution
my $distribution = $repository->distribution('Archive-Zip');
isa_ok( $distribution, 'ADAMK::Distribution' );

# Test the latest release
SCOPE: {
	my $release = $distribution->latest;
	isa_ok( $release, 'ADAMK::Release' );
	ok( -d $release->directory, '->directory ok' );
	is( $release->distname, 'Archive-Zip', '->distribution ok' );
	is( $release->file, 'Archive-Zip-1.27_01.tar.gz', '->file ok' );
	ok( -f $release->path, "->path exists at " . $release->path );
	isa_ok( $release->repository, 'ADAMK::Repository' );
	is( $release->version, '1.27_01', '->version ok' );

	# Extract it for examination
	my $extract = $release->extract;
	isa_ok( $extract, 'ADAMK::Release::Extract' );
	ok( -d $extract->path, '->extract ok' );

	# Find the version of Module::Install used for this release
	is( $extract->inc_module_install, undef, '->inc_module_install ok' );
}

# Test the latest stable release (it should be different)
SCOPE: {
	my $release = $distribution->stable;
	isa_ok( $release, 'ADAMK::Release' );
	ok( -d $release->directory, '->directory ok' );
	is( $release->distname, 'Archive-Zip', '->distribution ok' );
	is( $release->file, 'Archive-Zip-1.26.tar.gz', '->file ok' );
	ok( -f $release->path, "->path exists at " . $release->path );
	isa_ok( $release->repository, 'ADAMK::Repository' );
	is( $release->version, '1.26', '->version ok' );

	# Extract it for examination
	my $extract = $release->extract;
	isa_ok( $extract, 'ADAMK::Release::Extract' );
	ok( -d $extract->path, '->extract ok' );

	# Find the version of Module::Install used for this release
	is( $extract->inc_module_install, undef, '->inc_module_install ok' );	
}

# Test the oldest release
SCOPE: {
	my $release = $distribution->oldest;
	isa_ok( $release, 'ADAMK::Release' );
	ok( -d $release->directory, '->directory ok' );
	is( $release->distname, 'Archive-Zip', '->distribution ok' );
	is( $release->file, 'Archive-Zip-1.17_01.tar.gz', '->file ok' );
	ok( -f $release->path, "->path exists at " . $release->path );
	isa_ok( $release->repository, 'ADAMK::Repository' );
	is( $release->version, '1.17_01', '->version ok' );

	# Extract it for examination
	my $extract = $release->extract;
	isa_ok( $extract, 'ADAMK::Release::Extract' );
	ok( -d $extract->path, '->extract ok' );

	# Find the version of Module::Install used for this release
	is( $extract->inc_module_install, undef, '->inc_module_install ok' );	
}

# Test the oldest stable release (it should be different)
SCOPE: {
	my $release = $distribution->oldest_stable;
	isa_ok( $release, 'ADAMK::Release' );
	ok( -d $release->directory, '->directory ok' );
	is( $release->distname, 'Archive-Zip', '->distribution ok' );
	is( $release->file, 'Archive-Zip-1.18.tar.gz', '->file ok' );
	ok( -f $release->path, "->path exists at " . $release->path );
	isa_ok( $release->repository, 'ADAMK::Repository' );
	is( $release->version, '1.18', '->version ok' );

	# Extract it for examination
	my $extract = $release->extract;
	isa_ok( $extract, 'ADAMK::Release::Extract' );
	ok( -d $extract->path, '->extract ok' );

	# Find the version of Module::Install used for this release
	is( $extract->inc_module_install, undef, '->inc_module_install ok' );	
}

# Test something that should have M:I in use
SCOPE: {
	my $release = $repository->distribution('ADAMK-Repository')->oldest;
	isa_ok( $release, 'ADAMK::Release' );
	is( $release->version, '0.01', '->version ok' );
	my $extract = $release->extract;
	isa_ok( $extract, 'ADAMK::Release::Extract' );
	is( $extract->inc_module_install, '0.77', '->inc_module_install is 0.85 as expected' );
}

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
