#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 16;
use Test::NoWarnings;
use Test::POE::Stopping;
use POE::Declare::HTTP::Client;
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my $URL = 'http://www.google.com/';





######################################################################
# Test Object Generation

# Create the client
my @response = undef;
my $client   = POE::Declare::HTTP::Client->new(
	ResponseEvent => sub {
		order( 3, 'Got response' );
		isa_ok( $_[1], 'HTTP::Response' );
		isa_ok( $_[1]->request, 'HTTP::Request' );
		is( $_[1]->request->uri->as_string, $URL );
	},
	ShutdownEvent => sub {
		order( 5, 'Got client shutdown' );
	},
);
isa_ok( $client, 'POE::Declare::HTTP::Client' );






######################################################################
# Test Execution

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );

			# Start the timeout
			$_[KERNEL]->delay_set( startup  => 1 );
			$_[KERNEL]->delay_set( request  => 2 );
			$_[KERNEL]->delay_set( shutdown => 5 );
			$_[KERNEL]->delay_set( timeout  => 7 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );
			ok( $client->start, '->start ok' );
		},

		request => sub {
			order( 2, 'Fired main::request' );
			ok( $client->GET($URL), '->GET ok' );
		},

		shutdown => sub {
			order( 4, 'Fired main::shutdown' );
			ok( $client->stop, '->stop ok' );
		},

		timeout => sub {
			order( 6, 'Fired main::timeout' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;
