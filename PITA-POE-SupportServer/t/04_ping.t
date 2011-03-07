#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::POE::Stopping;
use PITA::SupportServer ();
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my $server = PITA::SupportServer->new(
	Hostname  => '127.0.0.1',
	Port      => 12345,
	Mirrors   => {},
	Program   => [
		$^X,
		'-MLWP::UserAgent',
		'-e',
		'LWP::UserAgent->new->get("http://127.0.0.1:12345/"); exit(0);',
	],
	ShutdownEvent => \&shutdown,
);
isa_ok( $server, 'PITA::SupportServer' );

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );
			ok( $server->start, '->start ok' );

			# Start the timeout
			$_[KERNEL]->delay_set( failure => 5 );
		},

		failure => sub {
			order( 3, 'Fired main::finished' );
			poe_stopping();
		},

	},
);

sub shutdown {
	order( 2, 'Fired main::shutdown' );
	ok( $server->stop, '->stop ok' );
}

$server->run or die "->run failed";
ok( 1, 'Server ->run ok' );
