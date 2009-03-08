#!/usr/bin/perl

use ExtUtils::testlib;

use Math::Random::ISAAC;

my $rng = Math::Random::ISAAC->new();

use Data::Dumper;

#printf("%.8lx", $rng->rand);
$rng->testout;
