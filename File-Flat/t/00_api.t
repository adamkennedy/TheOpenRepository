#!/usr/bin/perl -w

# Basic first pass API testing for File::Flat

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
use Test::More 'tests' => 63;
use File::Flat;

# Execute the tests
use Test::ClassAPI;
Test::ClassAPI->execute('complete');
exit(0);

# Define the API
__DATA__
File::Flat=class
File::Flat::Object=class

[File::Flat]
exists=method
isaFile=method
isaDirectory=method
canRead=method
canWrite=method
canReadWrite=method
canExecute=method
canOpen=method
canRemove=method
isText=method
isBinary=method
fileSize=method

open=method
getReadHandle=method
getWriteHandle=method
getAppendHandle=method
getReadWriteHandle=method
slurp=method
read=method
write=method
overwrite=method
append=method
truncate=method

copy=method
move=method
remove=method
prune=method
makeDirectory=method
errstr=method

[File::Flat::Object]
File::Flat=implements
new=method
