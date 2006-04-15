#!/usr/bin/perl -w

# API Testing for Algorithm::Dependency

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

# Load the API we will be testing
use Test::More 'tests' => 39;
use Test::ClassAPI;
use Algorithm::Dependency               ();
use Algorithm::Dependency::Ordered      ();
use Algorithm::Dependency::Source::File ();
use Algorithm::Dependency::Source::HoA  ();

# Execute the tests
Test::ClassAPI->execute('complete');
exit(0);

# Now, define the API for the classes
__DATA__

Algorithm::Dependency=class
Algorithm::Dependency::Item=abstract
Algorithm::Dependency::Ordered=class
Algorithm::Dependency::Source=abstract
Algorithm::Dependency::Source::File=class
Algorithm::Dependency::Source::HoA=class

[Algorithm::Dependency]
new=method
source=method
selected_list=method
selected=method
item=method
depends=method
schedule=method
schedule_all=method

[Algorithm::Dependency::Item]
new=method
id=method
depends=method

[Algorithm::Dependency::Ordered]
Algorithm::Dependency=isa

[Algorithm::Dependency::Source]
new=method
load=method
item=method
items=method
missing_dependencies=method

[Algorithm::Dependency::Source::File]
Algorithm::Dependency::Source=isa

[Algorithm::Dependency::Source::HoA]
Algorithm::Dependency::Source=isa
