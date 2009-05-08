#!/usr/bin/perl -T

# t/03live.t
#  Module live functionality tests (requires Internet connectivity)
#
# By Jonathan Yu <frequency@cpan.org>, 2006-2009. All rights reversed.
#
# $Id$
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;

use Test::More;

use WebService::UWO::Directory::Student;

unless ($ENV{TEST_INTERNET}) {
  plan skip_all => 'Set TEST_INTERNET to enable tests requiring Internet';
}

plan tests => 8;

my $dir = WebService::UWO::Directory::Student->new;

# Normal lookup functionality
my $res = $dir->lookup({
  first => 'Continuing',
  last  => 'Test',
});

is($res->[0]->{given_name}, 'Continuing', 'User found by name');
is($res->[0]->{last_name},  'Test');
is($res->[0]->{email},      'ctest@uwo.ca');
is($res->[0]->{faculty},    'Faculty of Graduate Studies');

# Reverse lookup functionality
$res = $dir->lookup({
  email => 'ctest@uwo.ca',
});

is($res->{given_name}, 'Continuing', 'User found by email reverse');
is($res->{last_name},  'Test');
is($res->{email},      'ctest@uwo.ca');
is($res->{faculty},    'Faculty of Graduate Studies');
