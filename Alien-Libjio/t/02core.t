#!/usr/bin/perl -T

# t/02core.t
#  Tests core functionality
#
# $Id: 03core.t 7088 2009-05-15 02:51:39Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More tests => 7;
use Test::NoWarnings;

my $obj = Alien::Libjio->new;

# These sets of tests depend on whether libjio is installed
SKIP: {
  skip 'tests for when libjio is installed', 4 unless $obj->installed;

  # We have to make sure to test the ExtUtils::Liblist method
  $obj->_try_liblist();

  # Everything should still be defined
  ok(ref $obj->cflags eq 'ARRAY', '->cflags returns an ARRAY ref');
  ok(ref $obj->ldflags eq 'ARRAY', '->ldflags returns an ARRAY ref');

  # Returns an array if calling in list context
  ok(scalar(@{$obj->cflags}) != 0, '->cflags returns a LIST');
  ok(scalar(@{$obj->ldflags}) != 0, '->ldflags returns a LIST');
};

# Make sure the returned values are false
SKIP: {
  skip 'tests for when libjio is not installed', 2 if $obj->installed;

  ok(!$obj->cflags, '->cflags is false');
  ok(!$obj->ldflags, '->cflags is false');
}
