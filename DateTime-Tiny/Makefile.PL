use strict;
use inc::Module::Install;

name           'DateTime-Tiny';
all_from       'lib/DateTime/Tiny.pm';
build_requires 'Test::More' => '0.47';

WriteAll;
