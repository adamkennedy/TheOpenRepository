#!/usr/bin/perl -T

# t/01meta.t
#  Tests that the META.yml meets the specification
#
# $Id: 01meta.t 5633 2009-03-14 20:00:03Z FREQUENCY@cpan.org $
#
# All rights to this test script are hereby disclaimed and its contents
# released into the public domain by the author. Where this is not possible,
# you may use this file under the same terms as Perl itself.

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan skip_all => 'Set TEST_AUTHOR to enable module author tests';
}

eval 'use Test::YAML::Meta';
if ($@) {
  plan skip_all => 'Test::YAML::Meta required to test META.yml';
}

plan tests => 2;

# counts as 2 tests
meta_spec_ok('META.yml', undef, 'META.yml matches the META-spec');
