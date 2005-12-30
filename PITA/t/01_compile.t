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

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'PITA' );
ok( $PITA::VERSION,         'PITA was loaded' );
ok( $PITA::Report::VERSION, 'PITA::Report was loaded' );
is( $PITA::VERSION, $PITA::Guest::Driver::VERSION,
	'PITA::Guest::Driver was loaded and versions match' );
is( $PITA::VERSION, $PITA::Host::ResultServer::VERSION,
	'PITA::Host::ResultServer was loaded and versions match' );

exit(0);
