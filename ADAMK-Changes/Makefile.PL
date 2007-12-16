use strict;
use inc::Module::Install;

name           'ADAMK-Changes';
all_from       'lib/ADAMK/Changes.pm';
requires       'Object::Tiny' => '1.03';
build_requires 'Test::More'   => '0.47';
build_requires 'File::Spec'   => '0.80';

WriteAll;
