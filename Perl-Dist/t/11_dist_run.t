#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Skip if not on Windows
use Test::More;
# use LWP::Online ':skip_all';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	};
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping multi-hour test' );
		exit(0);
	}
	if ( -d 'C:\\minicpan' and ! $ENV{TEST_PERLDIST_CPAN} ) {
		# This is a hack specifically for ADAMK's setup
		$ENV{TEST_PERLDIST_CPAN} = 'file:///C|/minicpan/';
	}
	unless ( $ENV{TEST_PERLDIST_CPAN} ) {
		plan( skip_all => 'Skipping multi-hour tests that require a live CPAN mirror' );
		exit(0);
	}
	plan( tests => 11 );
}

use File::Path ();
use File::Spec::Functions ':ALL';
use_ok( 't::lib::Test' );

# Create the dist object
my $dist = t::lib::Test->new2;
isa_ok( $dist, 't::lib::Test2' );

# Run the dist object, and ensure everything we expect was created
diag( "Building test dist, may take up to an hour... (sorry)" );
ok( $dist->run, '->run ok' );
ok( -f "C:/tmp/sp/image/c/bin/dmake.exe", 'Found dmake.exe' );
ok( -f "C:/tmp/sp/image/c/bin/startup/Makefile.in", 'Found startup' );
ok( -f "C:/tmp/sp/image/c/bin/pexports.exe", 'Found pexports' );
