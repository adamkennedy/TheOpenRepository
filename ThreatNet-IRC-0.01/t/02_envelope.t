#!/usr/bin/perl -w

# Tests for ThreatNet::IRC::Envelope

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

use Test::More tests => 5;
use ThreatNet::IRC ();





#####################################################################
# Main Tests (only very basic)

my $Message = bless {}, 'ThreatNet::Message';
isa_ok( $Message, 'ThreatNet::Message' );

my $Envelope = ThreatNet::IRC::Envelope->new(
	$Message, 'foo!bar@ali.as', 'threatnet'
	);
isa_ok( $Envelope, 'ThreatNet::IRC::Envelope' );
isa_ok( $Envelope->message, 'ThreatNet::Message' );
is( $Envelope->who, 'foo!bar@ali.as', '->who returns as expected' );
is( $Envelope->where, 'threatnet', '->where returns as expected' );

1;
