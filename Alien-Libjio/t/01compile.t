#!/usr/bin/perl -T

# t/01compile.t
#  Check that the module can be compiled and loaded properly.
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 01compile.t 6040 2009-04-07 00:25:30Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings; # 1 test

# Check that we can load the module
BEGIN {
  use_ok('Alien::Libjio');
}
