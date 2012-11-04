#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use File::Spec::Functions;
use Parse::CSV       ();
use AI::RandomForest ();

my $train = catfile('t', 'data', 'train.csv');
ok( -f $train, 'Found training data set' );





######################################################################
# Parser Checks

SCOPE: {
	my $parser = Parse::CSV->new(
		file   => $train,
		names  => 1,
		filter => sub {
			AI::RandomForest::Sample->new(%$_)
		},
	);
	isa_ok( $parser, 'Parse::CSV' );

	my $record = $parser->fetch;
	isa_ok( $record, 'AI::RandomForest::Sample' );
}

SCOPE: {
	my $parser = Parse::CSV->new(
		file => $train,
	);
	isa_ok($parser, 'Parse::CSV');

	my $table = AI::RandomForest::Table->from_parse_csv($parser);
	isa_ok($table, 'AI::RandomForest::Table' );
	is( $table->features, 1777, '->features = 1777' );
	is( $table->samples, 3751, '->samples = 3751' );
}
