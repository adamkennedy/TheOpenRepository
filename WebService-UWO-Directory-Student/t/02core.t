#!/usr/bin/perl -T

# t/02core.t
#  Core functionality tests that do not require Internet connectivity
#
# By Jonathan Yu <frequency@cpan.org>, 2006-2009. All rights reversed.
#
# $Id: 01kwalitee.t 5715 2009-03-20 14:22:51Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More;

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

# There is 1 non-method test
plan tests => (1 + scalar(@methods));

foreach my $meth (@methods) {
  ok(WebService::UWO::Directory::Student->can($meth),
    'Method "' . $meth . '" exists.');
}

# Test the constructor initialization
my $dir = WebService::UWO::Directory::Student->new;
isa_ok($dir, 'WebService::UWO::Directory::Student');
