#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online ':skip_all';
use File::Spec::Functions ':ALL';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	};
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
		exit(0);
	}
	if ( rel2abs( curdir() ) =~ m{\.} ) {
		plan( skip_all => 'Cannot be tested in a directory with an extension.' );
		exit(0);
	}
	plan( tests => 10 );
}

use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = t::lib::Test->new4(93);
isa_ok( $dist, 't::lib::TestPortable' );

# Run the dist object, and ensure everything we expect was created
my $time = scalar localtime();
diag( "Building test dist @ $time, may take several hours... (sorry)" );
ok( eval { $dist->run; 1; }, '->run ok' );
$time = scalar localtime();
diag( "Test dist finished @ $time." );

# Did we build 5.10.0?
ok(
	-f catfile( qw{ t tmp93 image perl bin perl510.dll } ),
	'Found Perl 5.10.0 DLL',
);

# Did we build the zip file
ok(
	-f catfile( qw{ t tmp93 output test-perl-5.10.0-alpha-1.zip } ),
	'Found zip file',
);

# Did we build it portable
ok(
	-f catfile( qw{ t tmp93 image portable.perl } ),
	'Found portable file',
);
ok(
	-f catfile( qw{ t tmp93 image perl site lib Portable.pm } ),
	'Found Portable.pm',
);
