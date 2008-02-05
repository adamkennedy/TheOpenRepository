use strict;
use inc::Module::Install;

name           'Win32-Wix';
all_from       'lib/Win32/Wix.pm';
requires       'Carp'           => 0;
requires       'XML::Generator' => '1.0';
requires       'File::ShareDir' => '0.04';
requires       'Object::Tiny'   => '1.00';
requires       'Params::Util'   => '0.25';
build_requires 'Test::More'     => '0.42';
install_share;

WriteAll;
