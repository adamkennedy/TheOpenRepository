#!/usr/bin/perl

# t/01kwalitee.t
#  Uses the CPANTS Kwalitee metrics to test the distribution
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 01kwalitee.t 6040 2009-04-07 00:25:30Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan skip_all => 'Set TEST_AUTHOR to enable module author tests';
}

eval {
  require Test::Kwalitee;
};
if ($@) {
  plan skip_all => 'Test::Kwalitee required to test distribution Kwalitee';
}

# Everything is set up, run the Kwalitee tests
Test::Kwalitee->import();
