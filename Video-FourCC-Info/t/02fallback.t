#!/usr/bin/perl -T

# t/02fallback.t
#  Tests core functionality
#
# $Id: 02manifest.t 5 2008-12-25 23:16:47Z frequency $
#
# This test script is hereby released into the public domain.

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

eval {
  require DateTime;
};
if ($@) {
  plan skip_all => 'DateTime required to test fallback';
}

eval {
  require Test::Without::Module;
};
if ($@) {
  plan skip_all => 'Test::Without::Module required to test fallback ability';
}

# Hide the DateTime package
Test::Without::Module->import('DateTime');

use Video::FourCC::Info;

# Check that the date parsed is appropriate
my $codec = Video::FourCC::Info->new('CC12');

# If there is no DateTime, then the registered date will be a simple
# string
is($codec->registered, '1996-06-12', 'Intel YUV12 codec register date');
