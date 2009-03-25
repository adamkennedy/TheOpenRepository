#!/usr/bin/perl -T

# t/04fallback.t
#  Tests use of the Pure Perl interface
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

# Cannot 'use' because we might skip tests
require Test::NoWarnings;

eval {
  require Test::Without::Module;
};
if ($@) {
  plan skip_all => 'Test::Without::Module required to test fallback ability';
}

plan tests => 5;

# Delay loading of test hooks
Test::NoWarnings->import();

# Hide the XS version
Test::Without::Module->import('Math::Random::ISAAC::XS');

use Math::Random::ISAAC;

my $rng = Math::Random::ISAAC->new();
isa_ok($rng, 'Math::Random::ISAAC');

ok($Math::Random::ISAAC::DRIVER eq 'PP', 'The Pure Perl port is loaded');
ok($rng->irand() > 0, 'Generate first integer in sequence');
ok($rng->rand()  > 0, 'Generate second number in sequence');


