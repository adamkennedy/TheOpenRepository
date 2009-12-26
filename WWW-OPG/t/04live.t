#!/usr/bin/perl -T

# t/04live.t
#  Module live functionality tests (requires Internet connectivity)
#
# $Id: 04live.t 10632 2009-12-26 03:17:29Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

use WWW::OPG;

unless ($ENV{HAS_INTERNET}) {
  plan skip_all => 'Set HAS_INTERNET to enable tests requiring Internet';
}

plan tests => 5;

my $opg = WWW::OPG->new;

eval {
  $opg->poll();
};

ok(!$@, 'No errors during retrieval');
diag($@) if $@;

ok($opg->last_updated <= DateTime->now, 'Last updated timestamp is ' .
  'earlier than or equal to current time');
ok($opg->last_updated >= DateTime->now->subtract(hours => 5),
  'Last update time is less than 5 hours ago');
ok($opg->power > 5_000, 'Generated power is greater than 5,000 MW');
ok($opg->power < 20_000, 'Generated power is greater than 20,000 MW');
