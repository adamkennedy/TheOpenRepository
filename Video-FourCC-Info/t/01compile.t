#!/usr/bin/perl -T

# t/01compile.t
#  Check that the module can be compiled and loaded properly.
#
# $Id$
#
# This test script is hereby released into the public domain.

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings; # 1 test

# Check that we can load the module
BEGIN {
  use_ok('Video::FourCC::Info');
}

# Avoid warnings like:
#  Name "DBD::SQLite::sqlite_version" used only once: possible typo
# This is the reason for 90% of the failing CPAN Testers reports
if (defined $DBD::SQLite::sqlite_version) { }
