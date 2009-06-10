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

use Test::More tests => 9;
use Test::NoWarnings;

use Alien::Libjio;

my $obj = Alien::Libjio->new;

isa_ok($obj, 'Alien::Libjio', 'Create an Alien::Libjio instance');
can_ok($obj, 'version');

# These sets of tests depend on whether libjio is installed
SKIP: {
  skip 'tests for when libjio is installed', 4 unless $obj->installed;

  # We have to make sure to test the ExtUtils::Liblist method
  $obj->_try_liblist();

  # Everything should still be defined
  ok(ref $obj->cflags eq 'ARRAY', '->cflags returns an ARRAY ref');
  ok(ref $obj->ldflags eq 'ARRAY', '->ldflags returns an ARRAY ref');

  # Returns an array if calling in list context
  my @a = $obj->cflags;
  ok(scalar(@a) > 0, '->cflags returns a LIST');
  @a = $obj->ldflags;
  ok(scalar(@a) > 0, '->ldflags returns a LIST');
};

# Make sure the returned values are false
SKIP: {
  skip 'tests for when libjio is not installed', 2 if $obj->installed;

  ok(!$obj->cflags, '->cflags is false');
  ok(!$obj->ldflags, '->ldflags is false');
}
