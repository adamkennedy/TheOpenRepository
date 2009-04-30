#!/usr/bin/perl

# t/03scripts.t
#  Test that included script files compile properly
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

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

eval {
  require Video::Info;
};
if ($@) {
  plan(skip_all => 'Video::Info required for bin/peekvideo');
}

Test::Script->import;

plan tests => 2;

script_compiles_ok('bin/peekvideo', 'peekvideo program compiles');
