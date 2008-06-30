use strict;
use inc::Module::Install;

name          'ADAMK-Release';
all_from      'lib/ADAMK/Release.pm';
requires      'Params::Util' => '0.20';
test_requires 'Test::More'   => '0.42';

WriteAll;
