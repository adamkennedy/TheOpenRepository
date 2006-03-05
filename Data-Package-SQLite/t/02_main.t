#!/usr/bin/perl -w

# Main testing script for Data::Package::SQLite

# Because the entire point of this module is to be relatively
# magic, it should be relatively safe to start by testing the
# most DWIM usage, and work our way towards the fine testing.

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
			);
	}
}

use Test::More tests => 2;

# Add the t/lib in both harness and non-harness cases
use lib catdir('t', 'lib');

# Load the test packages
use My::DataPackage1 ();
use My::DataPackage2 ();





#####################################################################
# Main testing

# The most DWIM test
SCOPE: {
	my $dbh = My::DataPackage1->get;
	isa_ok( $dbh, 'DBI::dbh' );
}

exit(0);
