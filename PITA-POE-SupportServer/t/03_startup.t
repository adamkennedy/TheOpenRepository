#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
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
	Hostname => '127.0.0.1',
	Port     => 12345,
	Mirrors  => {
		'/cpan.' => '.',
	},
	Program  => [
		$^X,
		'-e',
		'sleep 10;',
	],
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
			$_[KERNEL]->delay_set( timeout  => 2 );
			$_[KERNEL]->delay_set( finished => 5 );
		},

		timeout => sub {
			order( 1, 'Fired main::timeout' );
			ok( $server->stop, '->stop ok' );
		},

		finished => sub {
			order( 2, 'Fired main::finished' );
			poe_stopping();
		},

	},
);

$server->run or die "->run failed";
ok( 1, 'Server ->run ok' );
