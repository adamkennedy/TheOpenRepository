#!/usr/bin/perl -T

# t/02core.t
#  Tests core functionality
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 02core.t 7496 2009-06-13 04:17:20Z FREQUENCY@cpan.org $
#
# All rights to this test script are hereby disclaimed and its contents
# released into the public domain by the author. Where this is not possible,
# you may use this file under the same terms as Perl itself.

use strict;
use warnings;

use Test::More tests => 10;
use Test::NoWarnings;

use Env::Sanctify::Auto;

my $obj = Env::Sanctify::Auto->new;

isa_ok($obj, 'Env::Sanctify::Auto', 'Create a Env::Sanctify::Auto instance');
can_ok($obj, 'new');
can_ok($obj, 'sanctify');

# Check that the %ENV keys were removed
ok(!exists $ENV{CDPATH},      'Removes CDPATH');
ok(!exists $ENV{IFS},         'Removes IFS');
ok(!exists $ENV{ENV},         'Removes ENV');
ok(!exists $ENV{BASH_ENV},    'Removes BASH_ENV');

# Set a path ourselves, then check that the path is exactly what we put in
$obj = Env::Sanctify::Auto->new({
  path => '/dev/null/custom/path'
});

is($ENV{PATH}, '/dev/null/custom/path', 'Custom PATH set properly');

# Destroy the object, should restore everything
undef($obj);

isnt($ENV{PATH}, '/dev/null/custom/path', 'Normal PATH restored');
