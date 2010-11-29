#!/usr/bin/perl

# Tests for the experimental update methods

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 18_update.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file     => '$file',
	x_update => 1,
};

1;
END_PERL





#####################################################################
# Tests for the base package update methods

isa_ok(
	Foo::Bar::TableOne->create(
		col1 => 1,
		col2 => 'foo',
	),
	'Foo::Bar::TableOne',
);
isa_ok(
	Foo::Bar::TableOne->create(
		col1 => 2,
		col2 => 'bar',
	),
	'Foo::Bar::TableOne',
);
is( Foo::Bar::TableOne->count, 2, 'Found 2 rows' );
is(
	Foo::Bar->update(
		Foo::Bar::TableOne->table,
		{
			col2 => 'baz',
		},
	),
	2,
	'Updated 2 rows',
);
is(
	Foo::Bar::TableOne->count('where col2 = ?', 'baz'),
	2,
	'Updated 2 rows',
);
is(
	Foo::Bar->update(
		Foo::Bar::TableOne->table,
		{
			col2 => 'one',
		},
		'where col1 = ?', 1,
	),
	1,
	'Updated 1 rows',
);
is(
	Foo::Bar::TableOne->count('where col2 = ?', 'one'),
	1,
	'Updated 1 row',
);
is(
	Foo::Bar->update(
		Foo::Bar::TableOne->table,
		{
			col2 => 'three',
		},
		'where col1 = ?', 3,
	),
	'0E0',
	'Updated 0 rows',
);
is(
	Foo::Bar::TableOne->count('where col2 = ?', 'three'),
	0,
	'Updated 0 rows',
);
