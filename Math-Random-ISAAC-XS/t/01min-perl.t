#!/usr/bin/perl

# t/01min-perl.t
#  Tests that the minimum required Perl version matches META.yml
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 01min-perl.t 5715 2009-03-20 14:22:51Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan(skip_all => 'Set TEST_AUTHOR to enable module author tests');
}

eval {
  require Test::MinimumVersion;
};
if ($@) {
  plan skip_all => 'Test::MinimumVersion required to test minimum Perl';
}

Test::MinimumVersion->import();

all_minimum_version_from_metayml_ok();
