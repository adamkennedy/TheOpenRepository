#!/usr/bin/perl -T

# t/03exceptions.t
#  Tests fast errors produced with obvious mistakes
#
# $Id$

use strict;
use warnings;

use Test::More tests => 6;
use Test::NoWarnings;

use Alien::Libjio;

# Incorrectly called methods
{
  my $obj = Alien::Libjio->new();
  eval { $obj->new(); };
  ok($@, '->new called as an object method');

  eval { Alien::Libjio->installed; };
  ok($@, '->installed called as a class method');

  eval { Alien::Libjio->version; };
  ok($@, '->version called as a class method');

  eval { Alien::Libjio->ldflags; };
  ok($@, '->ldflags called as a class method');

  eval { Alien::Libjio->cflags; };
  ok($@, '->cflags called as a class method');
}
