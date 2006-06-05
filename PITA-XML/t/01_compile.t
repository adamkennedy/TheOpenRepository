#!/usr/bin/perl -w

# Compile-testing for PITA::XML

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

use Test::More tests => 24;

ok( $] > 5.005, 'Perl version is 5.004 or newer' );

use_ok( 'PITA::XML' );

foreach ( qw{Storable File Report Install Request Platform Guest Command Test SAXParser SAXDriver} ) {
	my $c = "PITA::XML::$_";
	ok( $c->VERSION, "$c is loaded" );
	is( $PITA::XML::VERSION, $c->VERSION,
		"$c \$VERSION matches main \$VERSION" );
}

exit(0);
