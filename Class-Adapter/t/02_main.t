#!/usr/bin/perl -w

# Main testing for Class::Adapter

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir(updir(), 'lib') );
	}
}

use Test::More tests => 13;
use Scalar::Util 'refaddr';
use Class::Adapter ();

# Create an object
my $object = bless {}, 'Foo';
isa_ok( $object, 'Foo' );

# Create an adapter
my $adapter = Class::Adapter->new( $object );
isa_ok( $adapter, 'Class::Adapter' );

# Do bad things to the constructor
is( Class::Adapter->new(), undef, 'Class::Adapter->new() returns undef' );
my @evil = ( undef, '', 1, 'foo', \"foo", [], {}, (sub { 1 }) );
foreach my $it ( @evil ) {
	is( Class::Adapter->new( $it ), undef,
		'Class::Adapter->new(evil) returns undef' );
}

# Can we get access to the underlying object?
isa_ok( $adapter->_OBJECT_, 'Foo' );
is( refaddr($object), refaddr($adapter->_OBJECT_),
	'->_OBJECT_ returns the original object' );

exit(0);
