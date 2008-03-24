use strict;
use inc::Module::Install;

name           'Win32-Env-Path';
all_from       'lib/Win32/Env/Path.pm';
requires       'warnings'           => 0;
requires       'Carp'               => 0;
requires       'File::Spec'         => '0.80';
requires       'Params::Util'       => '0.10';
requires       'Win32::TieRegistry' => '0.03';
build_requires 'Test::More'         => '0.47';
build_requires 'Test::Script'       => 0;
install_script 'script/win32envpath';

WriteAll;
