#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use DBI;
use ORLite ();

my $file = '02_create.db';
unlink( $file ) if -f $file;
END {
unlink( $file ) if -f $file;
}

# Connect
my $dbh  = DBI->connect("dbi:SQLite:$file");
isa_ok( $dbh, 'DBI::db' );

# Set up
ok( $dbh->do(<<'END_SQL'), 'create ok' );
create table table_one (
	column1 integer not null primary key,
	column2 string
)
END_SQL
ok(
	$dbh->do('insert into table_one values ( ?, ? )', {}, 1, 'foo'),
	'insert ok',
);
ok(
	$dbh->do('insert into table_one values ( ?, ? )', {}, undef, 'bar'),
	'insert ok',
);
ok( $dbh->disconnect, 'disconnect' );

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo;

use strict;
use ORLite '$file';

1;
END_PERL

# Fetch the objects
my @ones = Foo::TableOne->select('order by column1');
is( scalar(@ones), 2, 'Got 2 objects' );
isa_ok( $ones[0], 'Foo::TableOne' );
isa_ok( $ones[1], 'Foo::TableOne' );
