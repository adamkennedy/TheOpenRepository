use strict;
use inc::Module::Install;

name           'Algorithm-Dependency-Source-DBI';
all_from       'lib/Algorithm/Dependency/Source/DBI.pm';
requires       'DBI'                   => 0;
requires       'Params::Util'          => '0.23';
requires       'Algorithm::Dependency' => '1.102';
build_requires 'Test::More'            => '0.42';
build_requires 'File::Spec'            => '0.80';
build_requires 'File::Temp'            => 0;

# Additional dependencies for automated testing
if ( $ENV{AUTOMATED_TESTING} ) {
	requires 'DBD::SQLite' => '1.13';
}

WriteAll;
