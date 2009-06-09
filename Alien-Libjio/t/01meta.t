#!/usr/bin/perl -T

# t/01meta.t
#  Tests that the META.yml meets the specification
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 01meta.t 6040 2009-04-07 00:25:30Z FREQUENCY@cpan.org $
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
  require Test::YAML::Meta;
};
if ($@) {
  plan skip_all => 'Test::YAML::Meta required to test META.yml';
}

plan tests => 2;

Test::YAML::Meta->import();

# counts as 2 tests
meta_spec_ok('META.yml', undef, 'META.yml matches the META-spec');
