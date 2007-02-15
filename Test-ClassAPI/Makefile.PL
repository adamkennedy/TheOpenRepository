use strict;
use inc::Module::Install;

name           'Test-ClassAPI';
all_from       'lib/Test/ClassAPI.pm';
requires       'File::Spec'       => '0.83';
requires       'Class::Inspector' => '1.12';
requires       'Config::Tiny'     => '2.00';
build_requires 'Test::More'       => '0.47';

WriteAll;
