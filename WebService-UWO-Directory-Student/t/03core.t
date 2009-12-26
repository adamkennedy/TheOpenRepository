#!/usr/bin/perl -T

# t/03core.t
#  Core functionality tests that do not require Internet connectivity
#
# $Id$

use strict;
use warnings;

use Test::More;
use Test::NoWarnings; # 1 test

use WebService::UWO::Directory::Student;

# Check all core methods are defined
my @methods = (
  'new',

  # Public methods
  'lookup',

  # Private/internal methods
  '_query',
  '_parse',
);

# There are 2 non-method tests
plan tests => (2 + scalar(@methods));

foreach my $meth (@methods) {
  ok(WebService::UWO::Directory::Student->can($meth),
    'Method "' . $meth . '" exists.');
}

# Test the constructor initialization
my $dir = WebService::UWO::Directory::Student->new;
isa_ok($dir, 'WebService::UWO::Directory::Student');
