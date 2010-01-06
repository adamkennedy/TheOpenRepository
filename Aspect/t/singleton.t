#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Aspect;

# Convert Foo into a singleton class
aspect Singleton => 'Foo::new';

my $foo1 = Foo->new;
my $foo2 = Foo->new;
is( ref($foo1), ref($foo2), 'there can only be one' );

# Create a lexical singleton to ensure it handles global vs lexical properly
SCOPE: {
	my $aspect = aspect Singleton => 'Bar::new';
	isa_ok( $aspect, 'Aspect::Library::Singleton' );
}





######################################################################
# Test Class

package Foo;

sub new {
	bless {}, shift;
};

package Bar;

sub new {
	bless {}, shift;
}
