#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Test::POE::Stopping;
use File::Spec::Functions ':ALL';
use PITA::SupportServer ();
use POE;

my $upload = catfile( qw{ t mock upload.pl } );
ok( -f $upload, "Found $upload" );

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
	Program       => [ 'perl', $upload ],
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
			order( 2, 'Server ShutdownEvent' );
			$_[KERNEL]->alias_remove('test');
			$_[KERNEL]->alarm_remove_all;
			$_[KERNEL]->yield('done');
		},

		done => sub {
			order( 3, 'main::done' );
			poe_stopping();
		},

		timeout => sub {
			poe_stopping();
		},
	},
);

$server->run
