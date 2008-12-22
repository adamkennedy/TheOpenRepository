#!/usr/bin/perl

# t/01_kwalitee.t
#  Uses the CPANTS Kwalitee metrics to test the distribution
#
# $Id$

use strict;
BEGIN {
  $^W = 1;
}

use Test::More;

eval {
  require Test::Kwalitee;
};
if ($@) {
  plan skip_all => 'Test::Kwalitee required to test distribution Kwalitee';
}

Test::Kwalitee->import();
