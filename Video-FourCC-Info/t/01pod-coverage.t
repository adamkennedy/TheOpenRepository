#!/usr/bin/perl -T

# t/01pod-coverage.t
#  Ensures all subroutines are documented with POD
#
# $Id$

use strict;
use warnings;

use Test::More;


unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

my %MODULES = (
  'Test::Pod::Coverage' => 1.04,
);

while (my ($module, $version) = each %MODULES) {
  eval "use $module $version";
  next unless $@;

  if ($ENV{RELEASE_TESTING}) {
    die 'Could not load release-testing module ' . $module . ': ' . $@;
  }
  else {
    plan skip_all => $module . ' not available for testing';
  }
}

all_pod_coverage_ok();
