#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 7;
use File::Spec::Functions;
use Parse::CSV       ();
use AI::RandomForest ();

my $titanic = catfile('t', 'data', 'titanic-train.csv');
ok( -f $titanic, 'Found training data set' );





######################################################################
# Parser Checks

SCOPE: {
	my $parser = Parse::CSV->new(
		file   => $titanic,
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
		file => $titanic,
	);
	isa_ok($parser, 'Parse::CSV');

	my $table = AI::RandomForest::Table->from_parse_csv($parser);
	isa_ok($table, 'AI::RandomForest::Table' );
	is( $table->features, 11, '->features = 1777' );
	is( $table->samples, 891, '->samples = 3751' );
}
