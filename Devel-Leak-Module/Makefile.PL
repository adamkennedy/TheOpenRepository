use strict;
use inc::Module::Install;

name           'Devel-Leak-Module';
all_from       'lib/Devel/Leak/Module.pm';
build_requires 'Test::More'   => '0.47';
build_requires 'Test::Script' => '1.02';
install_script 'script/perlbloat';

WriteAll;
