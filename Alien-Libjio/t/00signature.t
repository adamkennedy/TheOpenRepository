#!/usr/bin/perl

# t/00signature.t
#  Test that the SIGNATURE matches the distribution
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 00signature.t 6040 2009-04-07 00:25:30Z FREQUENCY@cpan.org $
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
  require Test::Signature;
};
if ($@) {
  plan skip_all => 'Test::Signature required to test SIGNATURE files';
}

plan tests => 1;

Test::Signature->import();

signature_ok();
