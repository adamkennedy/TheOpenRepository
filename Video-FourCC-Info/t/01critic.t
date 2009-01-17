#!/usr/bin/perl -T

# t/01critic.t
#  Test the distribution using Perl::Critic for guidelines
#
# $Id: 01critic.t 5 2008-12-25 23:16:47Z frequency $
#
# This test script is hereby released into the public domain.

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
