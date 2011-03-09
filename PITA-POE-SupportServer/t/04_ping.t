#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Test::POE::Stopping;
use File::Spec::Functions ':ALL';
use PITA::SupportServer ();
use POE;

my $ping = catfile( qw{ t mock ping.pl } );
ok( -f $ping, "Found $ping" );

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my $server = PITA::SupportServer->new(
	Hostname      => '127.0.0.1',
	Port          => 12345,
	Mirrors       => { '/cpan.' => '.' },
	Program       => [ 'perl', $ping ],
	StartupEvent  => [ test => 'started'  ],
	ShutdownEvent => [ test => 'shutdown' ],
);
isa_ok( $server, 'PITA::SupportServer' );

# Set up the test session
POE::Session->create(
	inline_states => {
		_start => sub {
			order( 0, 'Fired main::_start' );
			$_[KERNEL]->alias_set('test');
			$_[KERNEL]->delay_set( timeout => 5 );
			$_[KERNEL]->yield('startup');
		},

		startup => sub {
			order( 1, 'Fired main::startup' );

			# Start the server
			ok( $server->start, '->start ok' );
		},

		started => sub {
			order( 2, 'Server StartupEvent' );
		},

		shutdown => sub {
			order( 3, 'Server ShutdownEvent' );
			is( $_[ARG1], 1, 'pinged ok' );
			is_deeply( $_[ARG2], [ ], 'mirrored is null' );
			is_deeply( $_[ARG3], [ ], 'uploaded is null' );
			$_[KERNEL]->alias_remove('test');
			$_[KERNEL]->alarm_remove_all;
			$_[KERNEL]->yield('done');
		},

		done => sub {
			order( 4, 'main::done' );
			poe_stopping();
		},

		timeout => sub {
			poe_stopping();
		},
	},
);

$server->run
