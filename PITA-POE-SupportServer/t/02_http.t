#!/usr/bin/perl

# Tests for the HTTP server component of the support server only

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use PITA::SupportServer::HTTP ();

# Create the web server
my $server = PITA::SupportServer::HTTP->new(
	Hostname => '127.0.0.1',
	Port     => 12345,
);
isa_ok( $server, 'PITA::SupportServer::HTTP' );

# Run the web server
$server->run;
