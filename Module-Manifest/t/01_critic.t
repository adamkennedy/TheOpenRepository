#!/usr/bin/perl -T

# t/01_critic.t
#  Test the distribution using Perl::Critic for guidelines
#
# $Id$

use strict;
BEGIN {
  $^W = 1;
}

use File::Spec;
use Test::More;

eval {
  require Test::Perl::Critic;
};
if ($@) {
  plan(skip_all => 'Test::Perl::Critic required to critique code');
}

my $rcfile = File::Spec->catfile('t', '01_critic.rc');
Test::Perl::Critic->import(-profile => $rcfile);
all_critic_ok();
