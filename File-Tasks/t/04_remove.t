#!/usr/bin/perl -w

# Test File::Tasks::Provider

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

# Execute the tests
use Test::More 'tests' => 5;
use File::Find::Rule ();
use File::Tasks     ();

my $delete_dir = catdir( 't.data', 'delete' );
ok( -d $delete_dir, "Found 'delete' test directory" );

# If we are executing this test inside of a CVS checkout, we need
# to make sure that we don't accidentally include CVS folders.
my $Rule;
if ( -d catdir( $delete_dir, 'CVS' ) ) {
	$Rule = File::Find::Rule->new;
	$Rule = $Rule->or(
		$Rule->new->directory->name('CVS')->prune->discard,
		$Rule->new,
		)->file;
}





#####################################################################
# Create a new File::Tasks

my $Script = File::Tasks->new;
isa_ok( $Script, 'File::Tasks' );
is( $Script->remove_dir( $delete_dir, $Rule ), 3,
	'->delete_dir returns the correct number of files remove' );
is( scalar($Script->paths), 3, 'Correct number of Tasks added' );
is( scalar($Script->tasks), 3, 'Correct number of Tasks added' );

exit(0);
