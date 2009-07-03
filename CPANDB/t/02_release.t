#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online ':skip_all';
unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
	exit(0);
}

plan( tests => 2 );

# Download and load the database
use_ok( 'CPANDB' );

# Test graph generation
my $graph = CPANDB->graph;
isa_ok( $graph, 'Graph::Directed' );
