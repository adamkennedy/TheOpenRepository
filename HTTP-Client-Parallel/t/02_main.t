#!/usr/bin/perl

use strict;
use Test::More 'no_plan';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec ();
use Data::Dumper;
use HTTP::Client::Parallel qw{ mirror get };

my $mirror_dir = File::Spec->catdir( 't', 'test-download' );
ok( -d $mirror_dir, 'Found mirror directory' );

my $client = HTTP::Client::Parallel->new;
isa_ok( $client, 'HTTP::Client::Parallel' );

# get
if ( 0 ) {
	my $responses = $client->get(
		'http://www.google.com',
		'http://www.yapc.org',
		'http://www.yahoo.com',
	);

	#warn Dumper( $responses );
}

# mirror
my $responses = $client->mirror(
	'http://www.google.com' => "$mirror_dir/google.html",
);

$responses = mirror(
	'http://www.google.com' => "$mirror_dir/google.html",
);

warn Dumper( $responses );
