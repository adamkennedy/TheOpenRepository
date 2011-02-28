#!/usr/bin/perl

# Tests for the HTTP server component of the support server only

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use File::Spec::Functions ':ALL';
use PITA::SupportServer::HTTP ();

my $minicpan = rel2abs( catdir( 't', 'minicpan' ), );
ok( -d $minicpan, 'Found minicpan directory' );

# Create the web server
my $server = PITA::SupportServer::HTTP->new(
	Hostname => '127.0.0.1',
	Port     => 12345,
	Mirrors  => {
		'/cpan/' => $minicpan,
	},
);
isa_ok( $server, 'PITA::SupportServer::HTTP' );

# Run the web server
$server->run;
