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
	plan( tests => 13 );
}

use t::lib::Test;





#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = t::lib::Test->new3(92);
isa_ok( $dist, 't::lib::Test5100' );

# Run the dist object, and ensure everything we expect was created
my $time = scalar localtime();
diag( "Building test dist @ $time, may take several hours... (sorry)" );
ok( eval { $dist->run; 1; }, '->run ok' );
$time = scalar localtime();
diag( "Test dist finished @ $time." );

# C toolchain files
ok(
	-f catfile( qw{ t tmp92 image c bin dmake.exe } ),
	'Found dmake.exe',
);
ok(
	-f catfile( qw{ t tmp92 image c bin startup Makefile.in } ),
	'Found startup',
);
ok(
	-f catfile( qw{ t tmp92 image c bin pexports.exe } ),
	'Found pexports',
);

# Perl core files
ok(
	-f catfile( qw{ t tmp92 image perl bin perl.exe } ),
	'Found perl.exe',
);

# Toolchain files
ok(
	-f catfile( qw{ t tmp92 image perl site lib LWP.pm } ),
	'Found LWP.pm',
);

# Custom installed file
ok(
	-f catfile( qw{ t tmp92 image perl site lib Config Tiny.pm } ),
	'Found Config::Tiny',
);

# Did we build 5.10.0?
ok(
	-f catfile( qw{ t tmp92 image perl bin perl510.dll } ),
	'Found Perl 5.10.0 DLL',
);
