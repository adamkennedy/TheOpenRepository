#!/usr/bin/perl -T

# t/01memory.t
#  Tests that there are no memory leaks
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id$
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More;

use Math::Random::ISAAC::PP ();

if (exists($INC{'Devel/Cover.pm'})) {
  plan skip_all => 'This test is not compatible with Devel::Cover';
}

eval {
  require Test::LeakTrace;
};
if ($@) {
  plan skip_all => 'Test::LeakTrace required to test memory leaks';
}

plan tests => 2;

Test::LeakTrace->import;

no_leaks_ok(sub {
  my $obj = Math::Random::ISAAC::PP->new(time);
  for (0..10) {
    $obj->irand();
  }
}, '->irand does not leak memory');

no_leaks_ok(sub {
  my $obj = Math::Random::ISAAC::PP->new(time);
  for (0..30) {
    $obj->rand();
  }
}, '->rand does not leak memory');
