#!/usr/bin/perl

# t/00_signature.t
#  Test that the SIGNATURE matches the distribution
#
# $Id$

use strict;
BEGIN {
  $^W = 1;
}

use Test::More tests => 1;

eval 'use Test::Signature';
if ($@) {
  plan(skip_all => 'Test::Signature required to test SIGNATURE files');
}

signature_ok();