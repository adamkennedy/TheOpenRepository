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

plan( tests => 6 );

# Download and load the database
use_ok( 'CPANDB' );





######################################################################
# CPANDB shortcuts

my $cpandb = CPANDB->distribution('CPANDB');
isa_ok( $cpandb, 'CPANDB::Distribution' );





######################################################################
# Graph.pm Integration

eval {
	require Graph;
};
SKIP: {
	skip("No Graph support available", 2) if $@;

	# Graph generation for the entire grap
	SCOPE: {
		my $graph = CPANDB->graph;
		isa_ok( $graph, 'Graph::Directed' );
	}

	# Graph generation for a single distribution
	SCOPE: {
		my $graph = $cpandb->dependency_graph;
		isa_ok( $graph, 'Graph::Directed' );
	}
}





######################################################################
# Graph::Easy Integration

eval {
	require Graph::Easy;
};
SKIP: {
	skip("No Graph::Easy support available", 1) if $@;

	# Graph::Easy generation for a single distribution
	SCOPE: {
		my $graph = $cpandb->dependency_easy;
		isa_ok( $graph, 'Graph::Easy' );
	}
}





######################################################################
# GraphViz Integration

eval {
	require GraphViz;
};
SKIP: {
	skip("No GraphViz support available", 1) if $@;

	# GraphViz generation for a single distribution
	SCOPE: {
		my $graph = $cpandb->dependency_graphviz;
		isa_ok( $graph, 'GraphViz' );
	}
}
