use strict;
use inc::Module::Install;

name           'ADAMK-Release';
all_from       'lib/ADAMK/Release.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
build_requires 'Test::More'   => '0.42';

WriteAll;
