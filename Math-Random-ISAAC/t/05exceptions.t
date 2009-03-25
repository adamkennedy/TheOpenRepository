#!/usr/bin/perl -T

# t/05exceptions.t
#  Tests fast errors produced with obvious mistakes
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 03uniform.t 5754 2009-03-25 18:31:57Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

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
