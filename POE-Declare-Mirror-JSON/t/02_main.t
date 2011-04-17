#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Test::NoWarnings;
use Test::POE::Stopping;
use POE::Declare::Mirror::JSON;
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my @mirrors = qw{
	http://ali.as/mirrorjson/
	http://ali.as/mirrorjson/test1/
	http://ali.as/mirrorjson/test2/
	http://ali.as/mirrorjson/test3/
	http://ali.as/mirrorjson/test4/
	http://ali.as/mirrorjson/test5/
	http://svn.ali.as/websites/ali.as/mirrorjson/
	http://svn.ali.as/websites/ali.as/mirrorjson/test1/
	http://svn.ali.as/websites/ali.as/mirrorjson/test2/
	http://svn.ali.as/websites/ali.as/mirrorjson/test3/
	http://svn.ali.as/websites/ali.as/mirrorjson/test4/
	http://svn.ali.as/websites/ali.as/mirrorjson/test5/
};





######################################################################
# Test Object Generation

my $client = POE::Declare::Mirror::JSON->new(
	Timeout        => 10,
	Parallel       => 10,
	SelectionEvent => sub {
		order( 2, 'Fired SelectionEvent' );
	},
	ErrorEvent     => sub {
		order( 2, 'Fired ErrorEvent' );
	}
);
isa_ok( $client, 'POE::Declare::Mirror::JSON' );





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
			$_[KERNEL]->delay_set( timeout  => 15 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );
			ok( $client->run, '->run ok' );
		},

		timeout => sub {
			order( 3, 'Fired main::timeout' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;
