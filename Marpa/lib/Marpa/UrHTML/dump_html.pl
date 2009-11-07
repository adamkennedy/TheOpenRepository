#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );

use Marpa::UrHTML;

my $document = do { local $RS = undef; <STDIN> };

my $p = Marpa::UrHTML->new( \$document );

my $value = $p->evaluate();

say ${$value};
