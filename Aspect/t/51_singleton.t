#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Aspect;

# Convert Foo into a singleton class
my $aspect = aspect 'Singleton' => 'Foo::new';

my $foo1 = Foo->new;
my $foo2 = Foo->new;
is( ref($foo1), ref($foo2), 'there can only be one' );





######################################################################
# Test Class

package Foo;

sub new {
	bless {}, shift;
};
