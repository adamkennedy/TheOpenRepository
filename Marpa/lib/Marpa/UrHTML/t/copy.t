#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use lib 'lib';

BEGIN {
    Test::More::use_ok('Marpa');
}

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open);

use Marpa::UrHTML;

my $document = do { local $RS = undef; open my $fh, q{<:utf8}, 'lib/Marpa/UrHTML/t/test.html'; <$fh> };

my $p = Marpa::UrHTML->new();
$p->document( \$document );
my $value = $p->value();

Test::More::is(${${$value}}, $document, 'Straight copy using defaults');
