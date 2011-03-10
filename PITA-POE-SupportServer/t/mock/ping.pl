#!/usr/bin/perl

use strict;
use POE::Declare::HTTP::Client ();

my $client = POE::Declare::HTTP::Client->new(
	ResponseEvent => \&response,
	ShutdownEvent => \&shutdown,
);
$client->start;
$client->GET($ARGV[0]);
sub response {
	# print $_[1]->code . ' ' . $_[1]->message . "\n";
	$client->stop;
}
sub shutdown {
	sleep 1;
	exit(0);
}

POE::Kernel->run;
