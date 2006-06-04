#!/usr/bin/perl -w

# Load the module with an existing database

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 14;

# Prepare to test
my $test_dir  = 't.data';
my $test_file = catfile( $test_dir, 'metrics.sqlite'    );
ok( -d $test_dir,  'Test directory exists'               );
ok( -r $test_dir,  'Test directory read permissions ok'  );
ok( -x $test_dir,  'Test directory enter permissions ok' );
ok( -f $test_file, 'Test file exists'                    );
ok( -r $test_file, 'Test file read permissions ok'       );
ok( -w $test_file, 'Test file write permissions ok'      );

# Do the whole thing in one hit...
use_ok( 'Perl::Metrics', $test_file );

# Get the database handle to the database
my $dbh = Perl::Metrics::CDBI->db_Main;
isa_ok( $dbh, 'DBI::db' );

# Does the expected tables exist?
my @tables = $dbh->tables('%', '%', '%');
ok( scalar(@tables), 'Got list of tables in the database' );
@tables = grep { ! /^sqlite_/ } @tables;
ok( scalar(@tables), 'Found at least one non-internal table' );
is( scalar(grep{ /\bfiles\b/ } @tables), 1,
	'Found files table' );
is( scalar(grep{ /\bmetrics\b/ } @tables), 1,
	'Found metrics table' );

# Searching for non-existant objects should return nothing, but not die
my @objects = Perl::Metrics::File->search( path => 'foo' );
is_deeply( \@objects, [ ], 'File->search does not die on search' );
@objects = Perl::Metrics::Metric->search( hex_id => '123' );
is_deeply( \@objects, [ ], 'File->search does not die on search' );

1;
