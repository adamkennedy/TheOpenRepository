#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::NoWarnings;
use Aegent::Class ();





######################################################################
# Trivial Constructor

# Create the test class stub
SCOPE: {
	package My::Class;

	use strict;
	use Aegent::Object ();

	our $VERSION = '0.01';
	our @ISA     = 'Aegent::Object';

	1;
}

my $class = Aegent::Class->new(
	name => 'My::Class'
);
isa_ok( $class, 'Aegent::Class' );

# Do the accessors work
is( $class->name, 'My::Class', '->name ok' );
is( $class->sequence, 0, '->sequence ok' );

# Do the trait-provided handles work
is( $class->sequence_nextval, 1, '->sequence_nextval ok' );
is( $class->attr_exists('foo'), 0, '->attr_exists ok' );
is( $class->attr_get('foo'), undef, '->attr_get ok' );
is_deeply(
	[ $class->attr_keys ],
	[ ],
	'->attr_keys ok',
);

# Do the non-moose methods work
is( $class->alias, 'My::Class.2', '->alias ok' );
