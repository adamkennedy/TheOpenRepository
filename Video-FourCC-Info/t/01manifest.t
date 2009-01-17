#!/usr/bin/perl -T

# t/01manifest.t
#  Ensures MANIFEST file is up-to-date
#
# $Id: 02manifest.t 5 2008-12-25 23:16:47Z frequency $
#
# This test script is hereby released into the public domain.

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan skip_all => 'Set TEST_AUTHOR to enable module author tests';
}

eval 'use Test::DistManifest';
if ($@) {
  plan skip_all => 'Test::DistManifest required to test MANIFEST files';
}

manifest_ok();
