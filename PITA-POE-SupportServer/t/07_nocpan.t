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
		plan tests => 4;
	}
};

use LWP::UserAgent;
use HTTP::Request;
use IO::Socket::INET;
use PITA::SupportServer ();

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

my $server = PITA::SupportServer->new(
	http_local_addr       => '127.0.0.1',
	http_local_port       => $port,
	http_startup_timeout  => 10,
	http_activity_timeout => 10,
	http_mirrors          => {},
	http_result           => '/result.xml',
	execute               => [ \&_lwp, $port ],
);

ok( 1, 'Server created' );

$server->prepare or die $server->{errstr};

ok( 1, 'Server prepared' );

$server->run;

ok( !$server->{exitcode}, 'Server ran and timed out' );

ok( $server->http_result( '/result.xml' ) eq 'Blah Blah Blah Blah Blah', 'Got result.xml' ); # 4

sub _lwp {
	my $port = shift || return;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	my $response = $ua->get("http://127.0.0.1:$port/");
	die unless $response->is_success;
	sleep 5;
	#my $content = $ua->get("http://127.0.0.1:$port/cpan/Makefile.PL");
	#die unless $content->is_success;
	my $request = HTTP::Request->new( PUT => "http://127.0.0.1:$port/result.xml" );
	$request->content("Blah Blah Blah Blah Blah");
	$ua->request( $request );
	sleep 5;
	return;
}
