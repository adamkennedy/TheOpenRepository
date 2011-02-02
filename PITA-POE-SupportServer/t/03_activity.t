#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan skip_all => 'Known-bad on Win32';
	} else {
		plan tests => 3;
	}
};

use LWP::UserAgent;
use IO::Socket::INET;
use PITA::POE::SupportServer ();

my $port;

SCOPE: {
	my $listen = IO::Socket::INET->new(
		Listen    => 5,
		LocalAddr => '127.0.0.1',
		Proto     => 'tcp',
		Reuse     => 1,
	) or die "$! creating socket\n";
	$port = $listen->sockport;
}

my $server = PITA::POE::SupportServer->new(
	http_local_addr       => '127.0.0.1',
	http_local_port       => $port,
	http_startup_timeout  => 10,
	http_activity_timeout => 10,
	http_mirrors          => { '/cpan', '.' },
	execute               => [ \&_lwp, $port ],
);

ok( 1, 'Server created' );

$server->prepare or die $server->{errstr};

ok( 1, 'Server prepared' );

$server->run;

ok( $server->{exitcode}, 'Server ran and timed out' );

sub _lwp {
	my $port = shift || return;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	my $response = $ua->get("http://127.0.0.1:$port/");
	die unless $response->is_success;
	sleep 60;
	return;
}
