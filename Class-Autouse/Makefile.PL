use strict;
use inc::Module::Install;

name           'Class-Autouse';
all_from       'lib/Class/Autouse.pm';
requires       'lib'        => 0;
requires       'constant'   => 0;
requires       'Carp'       => 0;
requires       'File::Spec' => '0.80';
requires       'List::Util' => '1.19';
test_requires 'base'       => 0;
test_requires 'Test::More' => '0.47';
test_requires 'File::Temp' => 0;

WriteAll;
