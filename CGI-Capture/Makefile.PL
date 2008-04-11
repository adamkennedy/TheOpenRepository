use strict;
use inc::Module::Install;

name           'CGI-Capture';
all_from       'lib/CGI/Capture.pm';
requires       'Carp'         => 0;
requires       'Storable'     => '2.11';
requires       'IO::Scalar'   => '2.110';
requires       'YAML::Tiny'   => '1.21';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.47';
test_requires 'Test::Script' => '1.02';
install_script 'script/cgicapture';

WriteAll;
