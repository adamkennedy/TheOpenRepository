#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 46;
use File::Spec::Functions ':ALL';
use DBI;
use ORLite ();

my $file = catfile(qw{ t simple.db });
      unlink( $file ) if -f $file;
END { unlink( $file ) if -f $file; }

# Connect
my %DBH = ();
$DBH{foo} = DBI->connect("dbi:SQLite:$file");
isa_ok( $DBH{foo}, 'DBI::db' );
$DBH{foo}->begin_work;
$DBH{foo}->rollback;

# Set up
ok( $DBH{foo}->do(<<'END_SQL'), 'create ok' );
create table table_one (
	col1 integer not null primary key,
	col2 string
)
END_SQL
ok( $DBH{foo}->disconnect, 'disconnect' );

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite '$file';

1;
END_PERL

Foo::Bar->begin;
Foo::Bar->rollback;

# Populate the test table
ok(
	Foo::Bar::TableOne->create( col1 => 1, col2 => 'foo' ),
	'Created row 1',
);
my $new = Foo::Bar::TableOne->create( col2 => 'bar' );
isa_ok( $new, 'Foo::Bar::TableOne' );
is( $new->col1, 2,     '->col1 ok' );
is( $new->col2, 'bar', '->col2 ok' );
ok(
	Foo::Bar::TableOne->create( col2 => 'bar' ),
	'Created row 3',
);

# Check the ->count method
is( Foo::Bar::TableOne->count, 3, 'Found 3 rows' );
is( Foo::Bar::TableOne->count('where col2 = ?', 'bar'), 2, 'Condition count works' );

# Fetch the rows (list context)
SCOPE: {
	my @ones = Foo::Bar::TableOne->select('order by col1');
	is( scalar(@ones), 3, 'Got 3 objects' );
	isa_ok( $ones[0], 'Foo::Bar::TableOne' );
	is( $ones[0]->col1, 1,     '->col1 ok' );
	is( $ones[0]->col2, 'foo', '->col2 ok' );
	isa_ok( $ones[1], 'Foo::Bar::TableOne' );
	is( $ones[1]->col1, 2,     '->col1 ok' );
	is( $ones[1]->col2, 'bar', '->col2 ok' );
	isa_ok( $ones[2], 'Foo::Bar::TableOne' );
	is( $ones[2]->col1, 3,     '->col1 ok' );
	is( $ones[2]->col2, 'bar', '->col2 ok' );
}

# Fetch the rows (scalar context)
SCOPE: {
	my $ones = Foo::Bar::TableOne->select('order by col1');
	is( scalar(@$ones), 3, 'Got 3 objects' );
	isa_ok( $ones->[0], 'Foo::Bar::TableOne' );
	is( $ones->[0]->col1, 1,     '->col1 ok' );
	is( $ones->[0]->col2, 'foo', '->col2 ok' );
	isa_ok( $ones->[1], 'Foo::Bar::TableOne' );
	is( $ones->[1]->col1, 2,     '->col1 ok' );
	is( $ones->[1]->col2, 'bar', '->col2 ok' );
	isa_ok( $ones->[2], 'Foo::Bar::TableOne' );
	is( $ones->[2]->col1, 3,     '->col1 ok' );
	is( $ones->[2]->col2, 'bar', '->col2 ok' );

	# Delete one of the objects via the class delete method
	my $rv1 = Foo::Bar::TableOne->delete('where col2 = ?', 'bar');
	is( $rv1, 2, 'Deleted 2 rows' );
	is( Foo::Bar::TableOne->count, 1, 'Confirm 2 rows were deleted' );

	# Delete one of the objects via the instance delete method
	ok( $ones->[0]->delete, 'Deleted object' );
	is( Foo::Bar::TableOne->count, 0, 'Confirm 1 row was deleted' );
}

# Database should now be empty
SCOPE: {
	my @none = Foo::Bar::TableOne->select;
	is_deeply( \@none, [ ], '->select ok with nothing' );

	my $none = Foo::Bar::TableOne->select;
	is_deeply( $none, [ ], '->select ok with nothing' );
}

# Transaction testing
SCOPE: {
	ok( Foo::Bar->begin, '->begin' );
	isa_ok( Foo::Bar::TableOne->create, 'Foo::Bar::TableOne' );
	is( Foo::Bar::TableOne->count, 1, 'One row created' );
	ok( Foo::Bar->rollback, '->rollback' );
	is( Foo::Bar::TableOne->count, 0, 'Commit ok' );

	ok( Foo::Bar->begin, '->begin' );
	isa_ok( Foo::Bar::TableOne->create, 'Foo::Bar::TableOne' );
	is( Foo::Bar::TableOne->count, 1, 'One row created' );
	ok( Foo::Bar->commit, '->commit' );
	is( Foo::Bar::TableOne->count, 1, 'Commit ok' );
}
