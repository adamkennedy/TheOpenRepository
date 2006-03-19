#!/usr/bin/perl -w

# Compile-testing for Perl::PowerToys

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
			'lib',
			);
	}
}

use Test::More tests => 2;

BEGIN {
	ok( $] > 5.005, 'Perl version is 5.005 or newer' );
	use_ok( 'PPI::PowerToys' );
}

exit(0);
