#!/usr/bin/perl

# t/01kwalitee.t
#  Uses the CPANTS Kwalitee metrics to test the distribution
#
# $Id: 01kwalitee.t 5 2008-12-25 23:16:47Z frequency $

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR}) {
  plan skip_all => 'Set TEST_AUTHOR to enable module author tests';
}

eval {
  require Test::Kwalitee;
};
if ($@) {
  plan skip_all => 'Test::Kwalitee required to test distribution Kwalitee';
}

Test::Kwalitee->import();
