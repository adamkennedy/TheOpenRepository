#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use AI::RandomForest::Selection ();





######################################################################
# Gini coefficient algorithms

SCOPE: {
	# Compare results to R implementation ineq::Gini
	is(
		AI::RandomForest::Selection::gini1( [ 1 ] ),
		0,
		'Gini(1) == 0',
	);
	is(
		AI::RandomForest::Selection::gini1( [ 1 .. 10 ] ),
		0.3,
		'Gini(1:10) == 0.3',
	);
	is( 
		AI::RandomForest::Selection::gini1( [ 1 .. 1000 ] ),
		0.333,
		'Gini(1:1000) == 0.333',
	);		
}
