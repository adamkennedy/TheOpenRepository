#!/usr/bin/perl

# t/01prereq.t
#  Checks that Build.PL prerequisites are correct
#
# $Id$
#
# This test script is hereby released into the public domain.

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan skip_all => 'Set TEST_AUTHOR to enable module author tests';
}

eval {
  require Test::Prereq::Build;
};
if ($@) {
  plan(skip_all => 'Test::Prereq::Build required to test prerequsites');
}

plan tests => 1;

# add a no-op; this should be committed upstream but is broken in 1.036
sub Test::Prereq::Build::add_build_element { 1 }

Test::Prereq::Build->import();

prereq_ok();
