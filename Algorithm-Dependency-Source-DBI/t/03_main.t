#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use File::Temp  ();
use DBI         ();
use DBD::SQLite ();

use Algorithm::Dependency              ();
use Algorithm::Dependency::Source::DBI ();





#####################################################################
# Main Tests

my $db = temp_db();
isa_ok( $db, 'DBI::db' );





#####################################################################
# Support Functions

sub temp_db {
	# Get a temp file name
	my $dir  = File::Temp::tempdir( CLEANUP => 1 );
	my $file = File::Spec->catfile( $dir, 'sqlite.db' );

	# Create the database
	my $dbh = DBI->connect( 'dbi:SQLite:' . $file );
	isa_ok( $dbh, 'DBI::db' );

	return $dbh;
}
