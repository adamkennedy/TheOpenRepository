#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use DBI;
BEGIN {
	plan( skip_all => 'Skipping ODBC driver test' );
	#if ( grep { $_ eq 'ODBC' } DBI->available_drivers ) {
		#plan( tests => 10 );
	#} else {
		#plan( skip_all => 'Skipping ODBC driver test' );
	#}
}
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use DBIx::Publish         ();

# Command row data
my @data = (
	[ 1, 'a', 'one'   ],
	[ 2, 'b', 'two'   ],
	[ 3, 'c', 'three' ],
	[ 4, 'd', 'four'  ],
);

# Locate the output database
my $output = catfile('t', 'output.sqlite');
File::Remove::clear($output);

# Connect to the source database
my $source = DBI->connect("DBI:ODBC:Book1", undef, undef, {
	ReadOnly   => 1,
	PrintError => 1,
	RaiseError => 1,
} );
isa_ok( $source, 'DBI::db' );

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

# Find the available tables
my @tables = grep { /table1/ } $source->tables;
is( scalar(@tables), 1, 'Found 1 table' );

# Clone a table completely
ok(
	$publish->table( 'simple3', $tables[0] ),
	'Created simple3 table',
);

# Clean up
ok( $publish->finish, '->finish ok' );

is_deeply(
	$publish->dbh->selectall_arrayref('select * from simple3'),
	\@data,
	'simple3 data ok',
);
