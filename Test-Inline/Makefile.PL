use inc::Module::Install 0.83;

all_from       'lib/Test/Inline.pm';
requires       'File::Spec'            => '0.80';
requires       'List::Util'            => '1.19';
requires       'Getopt::Long'          => '2.34';
requires       'File::Slurp'           => '9999.04';
requires       'File::Find::Rule'      => '0.26';
requires       'File::chmod'           => '0.31';
requires       'File::Remove'          => '0.37';
requires       'Config::Tiny'          => '2.00';
requires       'Params::Util'          => '0.21';
requires       'Class::Autouse'        => '1.15';
requires       'Algorithm::Dependency' => '1.02';
requires       'File::Flat'            => '1.00';
test_requires  'Test::More'            => '0.42';
test_requires  'Test::Script'          => '1.02';
test_requires  'Test::ClassAPI'        => '1.02';
install_script 'inline2test';

# Because some programs incorrectly do things like...
#
#   if ( installed('Test::Inline') ) { system('pod2test') }
#
# ... we need to make sure the legacy stuff it is installed.
requires       'Pod::Tests'            => '0.18';

WriteAll;
