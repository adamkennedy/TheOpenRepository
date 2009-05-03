#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use DBI;
BEGIN {
	unless ( grep { $_ eq 'mysql' } DBI->available_drivers ) {
		plan( skip_all => 'DBI driver mysql is not available' );
	}
	unless ( $ENV{XTRACT_MYSQL_DSN} ) {
		plan( skip_all => 'XTRACT_MYSQL_DSN not provided' );
	}
	unless ( $ENV{XTRACT_MYSQL_USER} ) {
		plan( skip_all => 'XTRACT_MYSQL_USER not provided' );
	}
	unless ( $ENV{XTRACT_MYSQL_PASSWORD} ) {
		plan( skip_all => 'XTRACT_MYSQL_PASSWORD not provided' );
	}
	plan( tests => 10 );
}
use File::Spec::Functions ':ALL';
use File::Remove          'clear';

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
my $source = DBI->connect(
	$ENV{XTRACT_MYSQL_DSN},
	$ENV{XTRACT_MYSQL_USER},
	$ENV{XTRACT_MYSQL_PASSWORD},
	{
		ReadOnly   => 1,
		PrintError => 1,
		RaiseError => 1,
	}
);
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
