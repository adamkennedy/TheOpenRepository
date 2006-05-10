use inc::Module::Install;

name           'Test-Inline';
all_from       'lib/Test/Inline.pm';
requires       'File::Spec'            => '0.80';
requires       'List::Util'            => '1.11';
requires       'Getopt::Long'          => '2.34';
requires       'File::Slurp'           => '9999.04';
requires       'File::Find::Rule'      => '0.26';
requires       'Config::Tiny'          => '2.00';
requires       'Params::Util'          => '0.05';
requires       'Class::Autouse'        => '1.15';
requires       'Algorithm::Dependency' => '1.02';
requires       'File::Flat'            => '0.95';
build_requires 'Test::More'            => '0.42';
build_requires 'Test::ClassAPI'        => '1.02';
include        'Test::ClassAPI';
include        'Class::Inspector';
install_script 'bin/inline2test';

# Because some programs incorrectly do things like...
#   if ( installed('Test::Inline') ) { system('pod2test') }
# ... we need to make sure it is installed.
requires       'Pod::Tests'            => '0.18';

WriteAll;
