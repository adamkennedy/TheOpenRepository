#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Spec::Functions ':ALL';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	if ( rel2abs( curdir() ) =~ m{\.} ) {
		plan( skip_all => 'Cannot be tested in a directory with an extension.' );
		exit(0);
	}
	plan( tests => 11 );
}

use t::lib::Test;





#####################################################################
# Constructor Test

# Create the dist object
my $dist = t::lib::Test->new1(50);
isa_ok( $dist, 't::lib::TestQuick' );

# Check useragent method
my $ua = $dist->user_agent;
isa_ok( $ua, 'LWP::UserAgent' );

# Run the dist object, and ensure everything we expect was created
ok( $dist->run, '->run ok' );
ok( -f catfile( qw{ t tmp50 image c bin dmake.exe } ), 'Found dmake.exe' );
ok( -f catfile( qw{ t tmp50 image c bin startup Makefile.in } ), 'Found startup' );
