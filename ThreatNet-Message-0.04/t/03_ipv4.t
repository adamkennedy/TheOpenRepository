#!/usr/bin/perl -w

# ThreatNet::Message basic functionality tests

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
use Test::More tests => 21;
use ThreatNet::Message::IPv4 ();

# Create the test data
my @good = (
	'123.123.123.123',
	'0.123.123.123',
	'123.123.123.123 comment',
	);
my @bad = (
	undef,
	[],
	\"stringref",
	{},
	sub () { 1 },
	'123.123.123.456'
	);

foreach my $ip ( @good ) {
	my ($nums) = $ip =~ /^([\d\.]+)/;
	my $Message = ThreatNet::Message::IPv4->new( $ip );
	isa_ok( $Message, 'ThreatNet::Message::IPv4' );
	isa_ok( $Message->IP, 'Net::IP' );
	is( $Message->ip, $nums, '->ip returns as expected' );
	ok( $Message->created, '->created returns true' );
	ok( $Message->event_time, '->event_time returns true' );
}

foreach my $ip ( @bad ) {
	my $Message = ThreatNet::Message::IPv4->new( $ip );
	is( $Message, undef, 'Bad value returns undef' );
}
