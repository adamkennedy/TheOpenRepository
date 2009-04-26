#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 20;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use DBIx::Publish         ();
use Aspect;

# aspect Profiler => call qr/^DBI::(?:connect|db::prepare|db::do|db::select|st::execute|st::fetch)/;
# aspect Profiler => call qr/^DBIx::Publish::/;

# Command row data
my @data = (
	[ 1, 'a', 'one'   ],
	[ 2, 'b', 'two'   ],
	[ 3, 'c', 'three' ],
	[ 4, 'd', 'four'  ],
);

# Locate the CVS database
my $input  = catfile('t', 'input.sqlite');
my $output = catfile('t', 'output.sqlite');
File::Remove::clear($input);
File::Remove::clear($output);

# Connect to the source database
my $source = DBI->connect("DBI:SQLite:$input", {
	AutoCommit => 1,
	PrintError => 1,
	RaiseError => 1,
} );
isa_ok( $source, 'DBI::db' );
$source->do(<<'END_SQL');
CREATE TABLE table1 (
	id INTEGER NOT NULL PRIMARY KEY,
	foo CHAR(1) NOT NULL,
	bar VARCHAR(10) NOT NULL
)
END_SQL
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	@{$data[0]},
);
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	@{$data[1]},
);
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	@{$data[2]},
);
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	@{$data[3]},
);

# Create the Publish object
my $publish = DBIx::Publish->new(
	file   => $output,
	source => $source,
);
isa_ok( $publish, 'DBIx::Publish' );
is( $publish->file, $output, '->file ok' );
ok( $publish->source, '->source ok' );
isa_ok( $publish->dbh, 'DBI::db', '->sqlite ok' );


# Prepare the SQLite database
ok( $publish->prepare, '->prepare' );

# Fill some basic tables from select queries
ok(
	$publish->select( 'simple1', 'select id, foo from table1 where id < ?', 4 ),
	'Created simple1 table',
);
ok(
	$publish->select( 'simple2', 'select id, bar from table1 where id > ?', 1 ),
	'Created simple2 table',
);

# Clone a table completely
ok(
	$publish->table( 'simple3', 'table1' ),
	'Created simple3 table',
);
ok(
	$publish->table( 'table1' ),
	'Created table1 table',
);

# Add indexes to the tables
ok( $publish->index_table('simple1'), '->index table' );
ok( $publish->index_table('simple2'), '->index table' );
ok( $publish->index_table('simple3'), '->index table' );
ok( $publish->index_table('table1'),  '->index table' );

# Clean up
ok( $publish->finish, '->finish ok' );

# Check the tables we created
is_deeply(
	$publish->dbh->selectall_arrayref('select * from simple1'),
	[ [ 1, 'a' ], [ 2, 'b' ], [ 3, 'c' ] ],
	'simple1 data ok',
);
is_deeply(
	$publish->dbh->selectall_arrayref('select * from simple2'),
	[ [ 2, 'two' ], [ 3, 'three' ], [ 4, 'four' ] ],
	'simple2 data ok',
);
is_deeply(
	$publish->dbh->selectall_arrayref('select * from simple3'),
	\@data,
	'simple3 data ok',
);
is_deeply(
	$publish->dbh->selectall_arrayref('select * from table1'),
	\@data,
	'table1 data ok',
);

# Check the indexes were created
my $rv = $publish->dbh->selectrow_arrayref(
	'SELECT COUNT(*) FROM sqlite_master WHERE type = ?',
	{}, 'index',
)->[0];
is( $rv, 10, 'Found 12 indexes' );
