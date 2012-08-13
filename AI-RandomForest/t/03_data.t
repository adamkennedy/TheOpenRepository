#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use File::Spec::Functions;
use Parse::CSV ();

my $train = catfile('t', 'data', 'train.csv');
ok( -f $train, 'Found training data set' );





######################################################################
# Parser Checks

my $parser = Parse::CSV->new(
	file => $train,
	names => 1,
);
isa_ok( $parser, 'Parse::CSV' );

my $record = $parser->fetch;
is( ref($record), 'HASH', 'Got the first record' );

1;
