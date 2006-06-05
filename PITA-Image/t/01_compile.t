#!/usr/bin/perl -w

# Compile-testing for PITA

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
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			'lib',
			);
	}
}

use Test::More tests => 6;

BEGIN {
	ok( $] > 5.005, 'Perl version is 5.005 or newer' );
	use_ok( 'PITA::Image'           );
	use_ok( 'PITA::Image::Platform' );
	use_ok( 'PITA::Image::Task'     );
	use_ok( 'PITA::Image::Discover' );
	use_ok( 'PITA::Image::Test'     );
}

exit(0);
