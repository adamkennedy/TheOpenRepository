#!/usr/bin/perl -w

# Test that CPAN::Data::Loader works

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 12;
use File::Remove       'remove';
use File::Copy         'copy';
use IO::File           ();
use CPAN::Data         ();
use CPAN::Data::Loader ();

# Locate and open a handle to the plain test author file
my $AUTHOR = catfile('t', 'data', '01mailrc.txt');
ok( -f $AUTHOR, "Found uncompressed author file at $AUTHOR" );





#####################################################################
# Setting Up

# Set up the test database
my $TESTDB = catfile('share', 'cpan.db');
my $MYDB   = catfile('t',     'cpan.db');
my $MYDSN  = "dbi:SQLite:$MYDB";
ok( -f $TESTDB, 'Found empty database' );
      remove($MYDB) if -f $MYDB;
END { remove($MYDB) if -f $MYDB; }
ok( copy( $TESTDB => $MYDB ), 'Create testing database' );

# Connect to the database
my $schema = CPAN::Data->connect( $MYDSN );
isa_ok( $schema, 'CPAN::Data', 'DBIx::Class::Schema' );





#####################################################################
# Loading the Database

# Load the authors
SCOPE: {
	my $authors = IO::File->new( $AUTHOR );
	isa_ok( $authors, 'IO::File', 'IO::Handle' );
	my $added = CPAN::Data::Loader->load_authors( $schema, $authors );
	is( $added, 9, 'Appeared to add 9 authors' );
	is( $schema->resultset('Author')->count, 9, 'Actually added 9 records' );
	my $aassad = $schema->resultset('Author')->find('AASSAD');
	isa_ok( $aassad, 'CPAN::Data::Author' );
	is( $aassad->id, 'AASSAD', '->id ok' );
	is( $aassad->name, "Arnaud 'Arhuman' Assad", '->name ok' );
	is( $aassad->email, 'arhuman@hotmail.com', '->email ok' );
	isa_ok( $aassad->address, 'Email::Address' );
}

exit(0);
