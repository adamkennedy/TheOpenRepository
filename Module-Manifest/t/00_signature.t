#!/usr/bin/perl

# t/00_signature.t
#  Test that the SIGNATURE matches the distribution
#
# $Id$

use strict;
BEGIN {
  $^W = 1;
}

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan skip_all => 'Set TEST_AUTHOR to enable module author tests';
}

eval 'use Test::Signature';
if ($@) {
  plan skip_all => 'Test::Signature required to test SIGNATURE files';
}

plan tests => 1;
signature_ok();
