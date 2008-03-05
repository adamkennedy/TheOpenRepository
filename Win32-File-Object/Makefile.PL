use strict;
use inc::Module::Install;

name           'Win32-File-Object';
all_from       'lib/Win32/File/Object.pm';
requires       'Win32::File'  => '0.05';
build_requires 'File::Spec'   => '0.80';
build_requires 'File::Remove' => '0.38';
build_requires 'Test::More'   => '0.42';

WriteAll;
