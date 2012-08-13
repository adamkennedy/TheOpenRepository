#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use File::Spec::Functions;
use Parse::CSV ();

my $train = catfile('t', 'data', 'train.csv');
ok( -f $train, 'Found training data set' );

my $parser = Parse::CSV->new(
	file => $train,
);
isa_ok( $parser, 'Parse::CSV' );
