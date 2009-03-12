#!/usr/bin/perl

use ExtUtils::testlib;

use Math::Random::ISAAC;

my $rng = Math::Random::ISAAC->new();

use Data::Dumper;

for (0..20) {
  printf("%02d: %u\n", $_, $rng->rand);
}
