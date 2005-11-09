#!/usr/bin/perl -w

# Test File::Tasks::Provider

use strict;
use File::Spec::Functions ':ALL';

# Execute the tests
use Test::More 'tests' => 5;
use File::Find::Rule ();
use File::Tasks      ();

my $delete_dir = catdir( 't.data', 'delete' );
ok( -d $delete_dir, "Found 'delete' test directory" );

# If we are executing this test inside of a CVS checkout, we need
# to make sure that we don't accidentally include CVS folders.
my $Rule;
if ( -d catdir( $delete_dir, '.svn' ) ) {
	$Rule = File::Find::Rule->new;
	$Rule = $Rule->or(
		$Rule->new->directory->name('.svn')->prune->discard,
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
