#!/usr/bin/perl -T

# t/03exceptions.t
#  Tests fast errors produced with obvious mistakes
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 03exceptions.t 7455 2009-06-10 13:25:37Z FREQUENCY@cpan.org $
#
# All rights to this test script are hereby disclaimed and its contents
# released into the public domain by the author. Where this is not possible,
# you may use this file under the same terms as Perl itself.

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Env::Sanctify::Auto;

# Incorrectly called methods
{
  my $obj = Env::Sanctify::Auto->new();
  eval { $obj->new(); };
  ok($@, '->new called as an object method');

  eval {
    Env::Sanctify::Auto->new([ 'Blah' ]);
  };
  ok($@, '->new called with an ARRAY ref');
}
