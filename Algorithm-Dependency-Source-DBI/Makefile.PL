use strict;
use inc::Module::Install;

name           'Algorithm-Dependency-Source-DBI';
all_from       'lib/Algorithm/Dependency/Source/DBI.pm';
requires       'DBI'                   => 0;
requires       'Params::Util'          => '0.23';
requires       'Algorithm::Dependency' => '1.102';
test_requires 'Test::More'            => '0.42';
test_requires 'File::Spec'            => '0.80';
test_requires 'File::Temp'            => 0;

# Additional dependencies for automated testing
if ( $ENV{AUTOMATED_TESTING} ) {
	print "AUTOMATED_TESTING enabled, adding additional test dependencies\n";
	requires 'Parse::CSV'  => '1.00';
	requires 'DBD::SQLite' => '1.13';
} else {
	print "AUTOMATED_TESTING not enabled\n";
}

WriteAll;
