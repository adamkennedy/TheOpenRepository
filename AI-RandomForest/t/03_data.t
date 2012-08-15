#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use File::Spec::Functions;
use Parse::CSV       ();
use AI::RandomForest ();

my $train = catfile('t', 'data', 'train.csv');
ok( -f $train, 'Found training data set' );





######################################################################
# Parser Checks

my $parser = Parse::CSV->new(
	file   => $train,
	names  => 1,
	filter => sub {
		AI::RandomForest::Instance->new(%$_)
	},
);
isa_ok( $parser, 'Parse::CSV' );

my $record = $parser->fetch;
isa_ok( $record, 'AI::RandomForest::Instance' );
