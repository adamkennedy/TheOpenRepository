#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use File::Temp  ();
use t::lib::SQLite::Temp;

use Algorithm::Dependency              ();
use Algorithm::Dependency::Source::DBI ();

my @create = map { catfile( 't', 'data', 'simple', $_ ) } qw{ create.sql one.csv links.csv };
foreach ( @create ) {
	ok( -f $_, "$_ exists" );
}





#####################################################################
# Main Tests

my $dbh = create_db(@create);
isa_ok( $dbh, 'DBI::db' );

my $select_ids     = "select id from one order by id";
my $select_depends = "select foo, bar from links";

# Create the source
my $source = Algorithm::Dependency::Source::DBI->new(
	dbh            => $dbh,
	select_ids     => $select_ids,
	select_depends => $select_depends,
);
isa_ok( $source, 'Algorithm::Dependency::Source' );
isa_ok( $source, 'Algorithm::Dependency::Source::DBI' );
isa_ok( $source->dbh, 'DBI::db' );
is_deeply( $source->select_ids,     [ $select_ids     ], '->select_ids ok'     );
is_deeply( $source->select_depends, [ $select_depends ], '->select_depends ok' );

ok( $source->load, '->load ok' );
