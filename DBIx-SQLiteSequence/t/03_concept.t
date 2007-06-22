#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use DBI;

my $main_file = catfile( 't', 'data', 'main.sqlite' );
my $seq_file  = catfile( 't', 'data', 'seq.sqlite'  );





#####################################################################
# Preparation

# Create a database connection to both databases
SCOPE: {
	my $main_dbh = DBI->connect('dbi:SQLite:$main_file');
	isa_ok( $main_dbh, 'DBI::db' );

	my $seq_dbh = DBI->connect('dbi:SQLite:$seq_file');
	isa_ok( $seq_dbh, 'DBI::db' );
}
