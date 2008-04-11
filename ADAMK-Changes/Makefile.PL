use strict;
use inc::Module::Install;

name           'ADAMK-Changes';
all_from       'lib/ADAMK/Changes.pm';
requires       'Object::Tiny' => '1.03';
test_requires 'Test::More'   => '0.47';
test_requires 'File::Spec'   => '0.80';

WriteAll;
