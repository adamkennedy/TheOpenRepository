use strict;
use inc::Module::Install;

name                  'Win32-Wix';
all_from              'lib/Win32/Wix.pm';
build_requires        'Test::More' => '0';
requires_external_bin 'candle';

WriteAll;
