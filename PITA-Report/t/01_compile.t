#!/usr/bin/perl -w

# Compile-testing for PITA::Report

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

use Test::More tests => 3;

ok( $] > 5.004, 'Perl version is 5.004 or newer' );

use_ok( 'PITA::Report' );
is( $PITA::Report::VERSION, $PITA::Report::Parser::VERSION,
	'$VERSION matches for ::Parser' );
is( $PITA::Report::VERSION, $PITA::Report::Configuration::VERSION,
	'$VERSION matches for ::Configuration' );
is( $PITA::Report::VERSION, $PITA::Report::Distribution::VERSION,
	'$VERSION matches for ::Distribution' );


exit(0);
