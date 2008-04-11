use strict;
use inc::Module::Install;

name           'Array-Window';
all_from       'lib/Array/Window.pm';
test_requires 'File::Spec' => '0.80';
test_requires 'Test::More' => '0.47';

WriteAll;
