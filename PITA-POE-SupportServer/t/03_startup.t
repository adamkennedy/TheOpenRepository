#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
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
		sub { sleep 60; },
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

$server->prepare or die "->prepare failed";
ok( 1, 'Server ->prepare ok' );

$server->run or die "->run failed";
ok( 1, 'Server ->run ok' );

$server->finish or die "->finish failed";
ok( 1, 'Server ->finish ok' );
