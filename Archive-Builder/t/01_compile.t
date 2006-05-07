#!/usr/bin/perl -w

# Load test the Archive::Builder module

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 6;

# Check their perl version
BEGIN {
	ok( $] >= 5.005, 'Your perl is new enough' );
}

# Load all of the classes
use_ok( 'Archive::Builder'             );
use_ok( 'Archive::Builder::Section'    );
use_ok( 'Archive::Builder::File'       );
use_ok( 'Archive::Builder::Generators' );
use_ok( 'Archive::Builder::Archive'    );

exit(0);
