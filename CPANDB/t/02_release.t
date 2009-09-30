#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
	exit(0);
}

plan( tests => 32 );

# Download and load the database
use_ok( 'CPANDB' );





######################################################################
# CPANDB shortcuts

my $d = CPANDB->distribution('Config-Tiny');
isa_ok( $d, 'CPANDB::Distribution' );
isa_ok( $d->uploaded_datetime, 'DateTime' );
isa_ok( $d->age, 'DateTime::Duration' );





######################################################################
# Graph.pm Integration

eval {
	require Graph;
};
SKIP: {
	skip("No Graph support available", 3) if $@;

	# Graph generation for the entire grap
	SCOPE: {
		my $graph = CPANDB->graph;
		isa_ok( $graph, 'Graph::Directed' );
	}

	# Graph generation for a single distribution
	SCOPE: {
		my $graph1 = $d->dependency_graph;
		isa_ok( $graph1, 'Graph::Directed' );

		my $graph2 = $d->dependency_graph( phase => 'runtime' );
		isa_ok( $graph2, 'Graph::Directed' );
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
		my $graph = $d->dependency_easy;
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
		my $graph = $d->dependency_graphviz;
		isa_ok( $graph, 'GraphViz' );
	}
}





######################################################################
# Quadrant Support

SCOPE: {
	my @latest = CPANDB::Distribution->select("order by uploaded desc limit 10");
	is( scalar(@latest), 10, 'Found the 10 latest results' );
	foreach ( @latest ) {
		isa_ok( $_, 'CPANDB::Distribution' );
		is( $_->quadrant, 1, $_->distribution . ' is in quadrant 1' );
	}
}





######################################################################
# Statistics Support

SCOPE: {
	my $vector = CPANDB::Distribution->vector('weight');
	isa_ok( $vector, 'Statistics::Basic::Vector' );
	my $age = CPANDB::Distribution->vector('age_months');
	isa_ok( $vector, 'Statistics::Basic::Vector' );
}
