use strict;
use inc::Module::Install;

name                  'Win32-Wix';
all_from              'lib/Win32/Wix.pm';
requires              'Carp'           => 0;
requires              'XML::Generator' => '1.0';
build_requires        'Test::More'     => '0.42';
requires_external_bin 'candle';
requires_external_bin 'light';
install_script        'pwix';

WriteAll;
