#!/usr/bin/perl -T

# t/05exceptions.t
#  Tests fast errors produced with obvious mistakes
#
# $Id$

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use Math::Random::ISAAC;

# Incorrectly called methods
{
  my $obj = Math::Random::ISAAC->new();
  eval { $obj->new(); };
  ok($@, '->new called as an object method');

  eval { Math::Random::ISAAC->rand(); };
  ok($@, '->rand called as a class method');

  eval { Math::Random::ISAAC->irand(); };
  ok($@, '->irand called as a class method');
}
