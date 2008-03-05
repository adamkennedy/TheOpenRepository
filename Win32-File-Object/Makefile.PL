use strict;
use inc::Module::Install;

name     'Win32-File-Object';
all_from 'lib/Win32/File/Object.pm';
requires 'Win32::File' => '0.28';

WriteAll;
