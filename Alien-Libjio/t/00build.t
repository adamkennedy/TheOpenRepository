#!/usr/bin/perl -T

# t/00build.t
#  Test that the build completed successfully
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 00signature.t 7455 2009-06-10 13:25:37Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use Module::Build;
my $builder = Module::Build->current;

SKIP: {
  skip('tests if libjio is built', 1) unless $builder->notes('build_libjio');

  ok($builder->notes('build_result'), 'The build completed successfully ' .
    '(according to make)');
}
