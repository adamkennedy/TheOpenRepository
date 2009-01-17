#!/usr/bin/perl -T

# t/01compile.t
#  Check that the module can be compiled and loaded properly.
#
# $Id: 01compile.t 5 2008-12-25 23:16:47Z frequency $
#
# This test script is hereby released into the public domain.

use strict;
use warnings;

use Test::More tests => 1;

# Check that we can load the module
BEGIN {
  use_ok('Video::FourCC::Info');
}
