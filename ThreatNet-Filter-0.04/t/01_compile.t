#!/usr/bin/perl -w

# Load test the ThreatNet::Filter module

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
use Test::More 'tests' => 6;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'ThreatNet::Filter'              );
use_ok( 'ThreatNet::Filter::Null'        );
use_ok( 'ThreatNet::Filter::Chain'       );
use_ok( 'ThreatNet::Filter::ThreatCache' );
use_ok( 'ThreatNet::Filter::Network'     );

1;
