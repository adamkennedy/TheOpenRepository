#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use AI::RandomForest ();





######################################################################
# Simple Branch Construction

my $b1 = AI::RandomForest::Branch->new(
	feature   => 'foo',
	separator => 5,
	left      => 0,
	right     => 1,
);
isa_ok( $b1, 'AI::RandomForest::Branch' );
is( $b1->feature, 'foo', '->variable ok' );
is( $b1->separator, 5, '->separator ok' );
is( $b1->left, 0, '->left ok' );
is( $b1->right, 1, '->right ok' );

my $b2 = AI::RandomForest::Branch->new(
	feature   => 'foo',
	separator => 10,
	left      => $b1,
	right     => 0,
);
isa_ok( $b2, 'AI::RandomForest::Branch' );
isa_ok( $b2->left, 'AI::RandomForest::Branch' );





######################################################################
# Simple Tree Construction

my $t1 = AI::RandomForest::Tree->new(
	root => $b2,
);
isa_ok( $t1, 'AI::RandomForest::Tree' );
isa_ok( $t1->root, 'AI::RandomForest::Branch' );
