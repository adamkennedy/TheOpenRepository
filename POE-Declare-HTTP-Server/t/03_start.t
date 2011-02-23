#!/usr/bin/perl

# Simple start/stop operation without making any requests

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Test::NoWarnings;
use POE::Declare::HTTP::Server ();
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}





######################################################################
# Test Class Generation

# Create the server
my $server = POE::Declare::HTTP::Server->new(
	Hostname => '127.0.0.1',
	Port     => '8010',
	Handler  => sub {
		my $response = shift;

		$response->code( 200 );
		$response->header( 'Content-Type' => 'text/plain' );
		$response->content( 'Hello World!' );

		return 1;
	},
);
isa_ok( $server, 'POE::Declare::HTTP::Server' );





######################################################################
# Test Execution

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );
			ok( $server->start, '->start ok' );

			# Start the timeout
			$_[KERNEL]->delay_set( timeout => 2 );
		},

		timeout => sub {
			order( 1, 'Fired main::timeout' );
			ok( $server->stop, '->stop ok' );
		},

		_stop => sub {
			order( 2, 'Fired main::_stop' );
		},

	},
);

POE::Kernel->run;
