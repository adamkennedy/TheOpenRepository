#!/usr/bin/perl -T

# t/02exceptions.t
#  Tests fast errors produced with obvious mistakes
#
# $Id: 02manifest.t 5 2008-12-25 23:16:47Z frequency $
#
# This test script is hereby released into the public domain.

use strict;
use warnings;

use Test::More tests => 11;
use Test::NoWarnings;

use Video::FourCC::Info;

# Missing parameters
{
  eval { Video::FourCC::Info->new };
  ok($@, 'Nonparameterized call to new method fails');

  eval { Video::FourCC::Info->describe };
  ok($@, 'Nonparameterized call to describe method fails');
}

# Nonexistent FourCC throws exception
{
  eval { Video::FourCC::Info->new('TEST') };
  ok($@, 'FourCC TEST to describe method fails');

  eval { Video::FourCC::Info->describe('TEST') };
  ok($@, 'FourCC TEST to describe method fails');
}

# Incorrectly called methods
{
  my $codec = Video::FourCC::Info->new('DIV3');

  eval { Video::FourCC::Info->code };
  ok($@, 'Static call to code method fails');

  eval { Video::FourCC::Info->description };
  ok($@, 'Static call to description method fails');

  eval { Video::FourCC::Info->owner };
  ok($@, 'Static call to owner method fails');

  eval { Video::FourCC::Info->registered };
  ok($@, 'Static call to registered method fails');

  eval { $codec->new('TEST') };
  ok($@, 'Object call to new method fails');

  eval { $codec->describe('TEST') };
  ok($@, 'Object call to describe method fails');
}
