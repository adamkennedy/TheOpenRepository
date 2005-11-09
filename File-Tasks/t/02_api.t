#!/usr/bin/perl -w

# Basic first pass API testing for File::Tasks

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

# Load the API to test it
use File::Tasks;

# Execute the tests
use Test::More 'tests' => 57;
use Test::ClassAPI;

# Execute the tests
Test::ClassAPI->execute('complete', 'collisions');

exit(0);

__DATA__

File::Tasks::Task=abstract

[File::Tasks]
new=method
provider=method
task=method
tasks=method
paths=method
add=method
edit=method
remove=method
remove_dir=method
set=method
clashes=method
test=method
execute=method
overlay=method

[File::Tasks::Task]
type=method
new=method
path=method
test=method
execute=method

[File::Tasks::Add]
File::Tasks::Task=isa
source=method
content=method

[File::Tasks::Edit]
File::Tasks::Task=isa
source=method
content=method

[File::Tasks::Remove]
File::Tasks::Task=isa

[File::Tasks::Provider]
compatible=method
content=method
