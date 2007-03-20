use strict;
use inc::Module::Install;

name           'Object-Tiny';
perl_version   '5.004';
all_from       'lib/Object/Tiny.pm';
build_requires 'Test::More' => '0.42';

WriteAll;
