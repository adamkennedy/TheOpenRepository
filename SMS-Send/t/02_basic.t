#!/usr/bin/perl -w

# Test the basic loading, initialisation, etc for SMS::Send.
# Don't actually send anything yet.

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

use Test::More tests => 3;
use SMS::Send;





#####################################################################
# Driver Detection

# Check for available drivers
my @drivers = SMS::Send->installed_drivers;

# Should contain our two test drivers
ok( scalar(@drivers) >= 2, 'Found at least 2 drivers' );
ok( scalar(grep { $_ eq 'Test' } @drivers) == 1, 'Found "Test" driver' );
ok( scalar(grep { $_ eq 'AU-Test' } @drivers) == 1, 'Found "AU-Test" driver' );

exit(0);
