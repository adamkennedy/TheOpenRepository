#!/usr/bin/perl -w

# Compile-testing for PITA::Guest::Driver::Qemu

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
			);
	}
}

use Test::More tests => 2;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'PITA::Guest::Driver::Qemu' );

exit(0);
