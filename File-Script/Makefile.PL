use strict;
use inc::Module::Install;

name           'File-Script';
all_from       'lib/File/Script.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
test_requires 'Test::More'   => '0.42';

WriteAll;
