#!/usr/bin/perl

# t/00signature.t
#  Test that the SIGNATURE matches the distribution
#
# $Id$

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan skip_all => 'Set TEST_AUTHOR to enable module author tests';
}

unless ($ENV{TEST_INTERNET}) {
  plan skip_all => 'Set TEST_INTERNET to enable tests requiring Internet';
}

eval {
  require Test::Signature;
};
if ($@) {
  plan skip_all => 'Test::Signature required to test SIGNATURE files';
}

plan tests => 1;

Test::Signature->import();

signature_ok();
