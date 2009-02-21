#!/usr/bin/perl

# t/03scripts.t
#  Test that included script files compile properly
#
# $Id: 01critic.t 5226 2009-02-08 00:06:30Z FREQUENCY@cpan.org $
#
# This test script is hereby released into the public domain.

use strict;
use warnings;

use Test::More;
use Test::NoWarnings; # 1 test

eval {
  require Test::Script;
};
if ($@) {
  plan(skip_all => 'Test::Script required to test scripts');
}

Test::Script->import;

plan tests => 2;

script_compiles_ok('bin/peekvideo', 'peekvideo program compiles');
