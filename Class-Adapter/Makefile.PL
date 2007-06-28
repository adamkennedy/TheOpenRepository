use strict;
use inc::Module::Install;

name           'Class-Adapter';
all_from       'lib/Class/Adapter.pm';
requires       'Carp'           => 0;
requires       'Scalar::Util'   => '1.10';
build_requires 'File::Spec'     => '0.80';
build_requires 'Test::More'     => '0.47';

WriteAll;
