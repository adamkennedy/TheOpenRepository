use strict;
use inc::Module::Install;

name           'Class-Autouse';
all_from       'lib/Class/Autouse.pm';
requires       'Carp'       => 0;
requires       'lib'        => 0;
requires       'constant'   => 0;
requires       'File::Spec' => '0.80';
requires       'List::Util' => '1.19';
build_requires 'Test::More' => '0.47';
build_requires 'base'       => 0;
build_requires 'File::Temp' => 0;

WriteAll;
