use strict;
use inc::Module::Install;

name           'Acme-Everything';
all_from       'lib/Acme/Everything.pm';
requires       'CPANPLUS'       => 0;
requires       'Class::Autouse' => '1.03';
test_requires 'File::Spec'     => '0.80';
test_requires 'Test::More'     => '0.47';

WriteAll;
