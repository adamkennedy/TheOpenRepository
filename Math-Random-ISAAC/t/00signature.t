#!/usr/bin/perl

# t/00signature.t
#  Test that the SIGNATURE matches the distribution
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
