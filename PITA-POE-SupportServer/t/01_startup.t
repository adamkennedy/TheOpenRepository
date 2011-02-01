#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use PITA::POE::SupportServer;

my $server = PITA::POE::SupportServer->new(
	http_local_addr      => '127.0.0.1',
	http_local_port      => 0,
	http_startup_timeout => 10,
	http_mirrors         => { '/cpan', '.' },
	execute              => [
		sub { sleep 60; },
	],
);
isa_ok( $server, 'PITA::POE::SupportServer' );

$server->prepare or die $server->{errstr};

ok( 1, 'Server prepared' );

$server->run;

ok( $server->{exitcode}, 'Server ran and timed out' );
