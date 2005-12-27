#!/usr/bin/perl -w

# Compile-testing for SMS::Send::AU::MyVodafone

use strict;
use lib ();
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

use Test::More tests => 4;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'SMS::Send' );
use_ok( 'SMS::Send::AU::MyVodafone' );

my @drivers = SMS::Send->installed_drivers;
is( scalar(grep { $_ eq 'AU::MyVodafone' } @drivers), 1, 'Found installed driver AU::MyVodafone' );

exit(0);
