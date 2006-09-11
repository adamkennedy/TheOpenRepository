#!/usr/bin/perl -w

# Compile testing for asa

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;





#####################################################################
# Create the test class

SCOPE: {
	package Foo;

	use POE::Declare;

	declare foo => 'Attribute';
	declare bar => 'Internal';
}





#####################################################################
# Tests

SCOPE: {
	# There should be no meta-object for the Foo class initially
	is( POE::Declare::meta('Foo'), undef, 'meta(Foo) is undef' );

	# Compile the class
	is( POE::Declare::compile('Foo'), 1, 'compile(Foo) returns true' );

	# Check the meta-object
	my $meta = POE::Declare::meta('Foo');
	isa_ok( $meta, 'POE::Declare::Meta' );
	is( $meta->name, 'Foo', '->name is ok' );
	is( ref($meta->{attr}), 'HASH', '->{attr} is a hash' );
	isa_ok( $meta->{attr}->{foo}, 'POE::Declare::Meta::Attribute' );
	isa_ok( $meta->{attr}->{bar}, 'POE::Declare::Meta::Internal'  );
	is(     $meta->{attr}->{foo}->name, 'foo', 'Attribute foo ->name ok' );
	is(     $meta->{attr}->{bar}->name, 'bar', 'Attribute bar ->name ok' );

	# Create an object
	my $object = Foo->new( foo => 'foo' );
	isa_ok( $object, 'Foo' );
	is( $object->foo,   'foo',   '->foo created and returns correctly' );
	is( $object->Alias, 'Foo.1', 'Pregenerated ->Alias returns as expected' );
}

exit(0);
