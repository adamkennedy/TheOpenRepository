#!/usr/bin/perl -T

# t/01manifest.t
#  Ensures MANIFEST file is up-to-date
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 01manifest.t 6040 2009-04-07 00:25:30Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

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
