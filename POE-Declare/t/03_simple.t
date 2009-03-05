#!/usr/bin/perl

# Compile testing for asa

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 33;





#####################################################################
# Create the test class

SCOPE: {
	package Foo;

	use POE::Declare;
	use POE qw{ Session };

	# Shut up a warning
	POE::Kernel->run;

	# Check that SELF is exported, and matches HEAP
	main::is( SELF, HEAP, 'SELF == HEAP' );

	declare foo => 'Attribute';
	declare bar => 'Internal';

	sub findme : Event {
		my $self = $_[SELF];
		return $self;
	}

	$Foo::to = 0;
	sub to : Timeout(30) {
		my $self = $_[SELF];
		$Foo::to++;
	}

	1;
}





#####################################################################
# Tests

SCOPE: {
	# There should be no meta-object for the Foo class initially
	is( POE::Declare::meta('Foo'), undef, 'meta(Foo) is undef' );

	# Compile the class
	SCOPE: {
		package Foo;
		Test::More::is(
			POE::Declare::compile,
			1,
			'compile(Foo) returns true',
		);
	}

	# Check the meta-object
	my $meta = POE::Declare::meta('Foo');
	isa_ok( $meta, 'POE::Declare::Meta' );
	is( $meta->name, 'Foo', '->name is ok' );
	is( ref($meta->{attr}), 'HASH', '->{attr} is a hash' );
	isa_ok( $meta->{attr}->{foo},    'POE::Declare::Meta::Attribute' );
	isa_ok( $meta->{attr}->{bar},    'POE::Declare::Meta::Internal'  );
	isa_ok( $meta->{attr}->{findme}, 'POE::Declare::Meta::Event'     );
	isa_ok( $meta->{attr}->{to},     'POE::Declare::Meta::Timeout'   );
	is( $meta->{attr}->{foo}->name,    'foo',    'Attribute foo ->name ok'    );
	is( $meta->{attr}->{bar}->name,    'bar',    'Attribute bar ->name ok'    );
        is( $meta->{attr}->{findme}->name, 'findme', 'Attribute findme ->name ok' );
	is( $meta->{attr}->{to}->name,     'to',     'Attribute to ->name ok'     );

	# Create an object
	my $object = Foo->new( foo => 'foo' );
	isa_ok( $object, 'Foo' );
	is( $object->foo,   'foo',   '->foo created and returns correctly' );
	is( $object->Alias, 'Foo.1', 'Pregenerated ->Alias returns as expected' );

	# Check the attr method
	isa_ok( $meta->attr('foo'),    'POE::Declare::Meta::Attribute' );
	isa_ok( $meta->attr('bar'),    'POE::Declare::Meta::Internal'  );
	isa_ok( $meta->attr('findme'), 'POE::Declare::Meta::Event'     );
	isa_ok( $meta->attr('to'),     'POE::Declare::Meta::Timeout'   );
	is( $meta->attr('foo')->name,    'foo',    'Attribute foo ->name ok'    );
	is( $meta->attr('bar')->name,    'bar',    'Attribute bar ->name ok'    );
	is( $meta->attr('findme')->name, 'findme', 'Attribute findme ->name ok' );
	is( $meta->attr('to')->name,     'to',     'Attribute to ->name ok'     );

	# Check the package_states method
	is_deeply(
		[ $meta->package_states ],
		[ '_start', '_stop', 'findme', 'to' ],
		'->package_states returns as expected',
	);

	# Check the behaviour of SELF in methods
	$object->spawn;
	my $me = $object->call('findme');
	is_deeply( $me, $object, 'SELF works in methods' );
	$object->call('to');
	is( $Foo::to, 1, 'Timeout method called directly increments to' );
}





#####################################################################
# Create a subclass

SCOPE: {
	package My::Foo;

	use vars qw{@ISA};
	BEGIN {
		@ISA = 'Foo';
	}

	use POE::Declare;

	declare baz     => 'Attribute';
	declare MyParam => 'Param';

	compile;
}





#####################################################################
# Testing the subclass

SCOPE: {
	my $meta = POE::Declare::meta('My::Foo');
	isa_ok( $meta, 'POE::Declare::Meta' );
	is( $meta->name, 'My::Foo', '->name ok' );

	# Check the attr method
	isa_ok( $meta->attr('baz'), 'POE::Declare::Meta::Attribute' );
	isa_ok( $meta->attr('MyParam'), 'POE::Declare::Meta::Param' );
	isa_ok( $meta->attr('foo'), 'POE::Declare::Meta::Attribute' );
}
