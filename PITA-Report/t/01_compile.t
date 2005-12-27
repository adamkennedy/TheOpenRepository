#!/usr/bin/perl -w

# Compile-testing for PITA::Report

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

use Test::More tests => 9;

ok( $] > 5.005, 'Perl version is 5.004 or newer' );

use_ok( 'PITA::Report' );
is( $PITA::Report::VERSION, $PITA::Report::Install::VERSION,
	'$VERSION matches for ::Install' );
is( $PITA::Report::VERSION, $PITA::Report::Request::VERSION,
	'$VERSION matches for ::Request' );
is( $PITA::Report::VERSION, $PITA::Report::Platform::VERSION,
	'$VERSION matches for ::Platform' );
is( $PITA::Report::VERSION, $PITA::Report::Command::VERSION,
	'$VERSION matches for ::Command' );
is( $PITA::Report::VERSION, $PITA::Report::Test::VERSION,
	'$VERSION matches for ::Test' );
is( $PITA::Report::VERSION, $PITA::Report::SAXParser::VERSION,
	'$VERSION matches for ::SAXParser' );
is( $PITA::Report::VERSION, $PITA::Report::SAXDriver::VERSION,
	'$VERSION matches for ::SAXDriver' );

exit(0);
