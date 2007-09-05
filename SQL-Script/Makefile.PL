use strict;
use inc::Module::Install;

name           'SQL-Script';
all_from       'lib/SQL/Script.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.10';
build_requires 'Test::More'   => '0.42';
build_requires 'File::Spec'   => '0.80';

WriteAll;
