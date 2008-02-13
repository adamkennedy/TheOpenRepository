#!/usr/bin/perl -w

# Load test the ThreatNet::IRC modules

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}





# Does everything load?
use Test::More 'tests' => 3;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'ThreatNet::IRC'           );
use_ok( 'ThreatNet::IRC::Envelope' );

1;
