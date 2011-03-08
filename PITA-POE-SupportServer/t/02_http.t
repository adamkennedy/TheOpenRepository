#!/usr/bin/perl

# Tests for the HTTP server component of the support server only

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use PITA::SupportServer::HTTP ();
use POE::Declare::HTTP::Client ();
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my $minicpan = rel2abs( catdir( 't', 'minicpan' ), );
ok( -d $minicpan, 'Found minicpan directory' );

# Create the test client
my $client = POE::Declare::HTTP::Client->new(
	ResponseEvent => sub {
		order( 4, 'Client ResponseEvent' );
	},
	ShutdownEvent => sub {
		
	},
);
isa_ok( $client, 'POE::Declare::HTTP::Client' );

# Create the web server
my $server = PITA::SupportServer::HTTP->new(
	Hostname => '127.0.0.1',
	Port     => 12345,
	Mirrors  => {
		'/cpan/' => $minicpan,
	},
	StartupEvent => sub {
		order( 2, 'Server StartupEvent' );
		ok( $client->start, '->start ok' );
		ok( $client->GET('http://127.0.0.1:12345/'), '->GET ok' );
	},
	PingEvent => sub {
		order( 3, 'Server PingEvent' );
	},
);
isa_ok( $server, 'PITA::SupportServer::HTTP' );

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );

			# Start the timeout
			$_[KERNEL]->delay_set( startup => 1 );
			$_[KERNEL]->delay_set( timeout => 2 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );
			ok( !$client->spawned, 'Client not spawned' );
			ok( !$server->spawned, 'Server not spawned' );
			ok( $server->start, '->start ok' );
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
