#!/usr/bin/perl -w

# Basic functionality testing for File::BLOB

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 2;
use File::BLOB ();





#####################################################################
# Test creation from a CGI object

SKIP: {
	skip( 'CGI feature not yet implemented', 2 );
	1;
}

exit(0);
