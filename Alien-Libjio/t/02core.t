#!/usr/bin/perl

# t/02core.t
#  Tests core functionality
#
# $Id$

use strict;
use warnings;

use Test::More tests => 10;
use Test::NoWarnings;

use Alien::Libjio;

my $obj = Alien::Libjio->new;

isa_ok($obj, 'Alien::Libjio', 'Create an Alien::Libjio instance');
can_ok($obj, 'version');

# These sets of tests depend on whether libjio is installed
SKIP: {
  skip('tests for when libjio is installed', 5) unless $obj->installed;

  # If we got our config from pkg-config, do it again with ExtUtils::Liblist
  # so we can test that method too.
  $obj->_try_liblist() if $obj->how eq 'pkg-config';

  # Now that we've done liblist, our method should be 'ExtUtils::Liblist'
  is($obj->method, 'ExtUtils::Liblist', 'Detection method is correct');

  # Everything should still be defined
  is(ref $obj->cflags,  'ARRAY', '->cflags returns an ARRAY ref');
  is(ref $obj->ldflags, 'ARRAY', '->ldflags returns an ARRAY ref');

  # Returns an array if calling in list context
  my @a = $obj->cflags;
  ok(scalar(@a) > 0, '->cflags returns a LIST');
  @a = $obj->ldflags;
  ok(scalar(@a) > 0, '->ldflags returns a LIST');
};

# Make sure the returned values are false
SKIP: {
  skip('tests for when libjio is not installed', 2) if $obj->installed;

  ok(!$obj->cflags, '->cflags is false');
  ok(!$obj->ldflags, '->ldflags is false');
}
