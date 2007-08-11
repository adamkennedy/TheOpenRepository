#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use t::lib::SQLite::Temp;

my $sql_file = catfile( 't', 'data', 'selftest', 'create.sql' );
ok( -f $sql_file, 'Test SQL file exists' );
my $csv_file = catfile( 't', 'data', 'selftest', 'one.csv' );
ok( -f $csv_file, 'Test CSV file exists' );





#####################################################################
# Testing SQLite::Temp

SCOPE: {
	my $db = empty_db();
	isa_ok( $db, 'DBI::db' );
}

SCOPE: {
	my $db = create_db( $sql_file, $csv_file );
	isa_ok( $db, 'DBI::db' );

	my $data = $db->selectall_arrayref( 'select * from one order by foo' );
	is_deeply( $data, [
		[ 1, 'Hello, World!' ],
		[ 2, 'secondrow'     ],
	], 'Data in table one matches expected' );

	my $rv = $db->selectrow_arrayref( 'select count(*) from two' );
	is_deeply( $rv, [ 0 ], 'Nothing in table two' );
}
