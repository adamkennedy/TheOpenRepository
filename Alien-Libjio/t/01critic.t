#!/usr/bin/perl -T

# t/01critic.t
#  Test the distribution using Perl::Critic for guidelines
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 01critic.t 5715 2009-03-20 14:22:51Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More;
use File::Spec;

unless ($ENV{TEST_AUTHOR}) {
  plan(skip_all => 'Set TEST_AUTHOR to enable module author tests');
}

eval {
  require Test::Perl::Critic;
};
if ($@) {
  plan(skip_all => 'Test::Perl::Critic required to critique code');
}

my $rcfile = File::Spec->catfile('t', '01critic.rc');
Test::Perl::Critic->import(-profile => $rcfile);

all_critic_ok();
