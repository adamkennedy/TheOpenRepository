#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use AI::RandomForest::Math ();





######################################################################
# Gini coefficient algorithms

SCOPE: {
	# Compare results to R implementation ineq::Gini
	is(
		AI::RandomForest::Math::gini( [ 1 ] ),
		0,
		'Gini(1) == 0',
	);
	is(
		AI::RandomForest::Math::gini( [ 1 .. 10 ] ),
		0.3,
		'Gini(1:10) == 0.3',
	);
	is( 
		AI::RandomForest::Math::gini( [ 1 .. 1000 ] ),
		0.333,
		'Gini(1:1000) == 0.333',
	);		
}
