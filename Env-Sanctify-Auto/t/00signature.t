#!/usr/bin/perl

# t/00signature.t
#  Test that the SIGNATURE matches the distribution
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id$
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

unless ($ENV{TEST_INTERNET}) {
  plan skip_all => 'Set TEST_INTERNET to enable tests requiring Internet';
}

eval 'use Test::Signature';
if ($@) {
  plan skip_all => 'Test::Signature required to test SIGNATURE files';
}

plan tests => 1;

signature_ok(); # 1 test
