use strict;
use inc::Module::Install;

name           'Devel-Leak-Module';
all_from       'lib/Devel/Leak/Module.pm';
test_requires 'Test::More'   => '0.47';
test_requires 'Test::Script' => '1.02';
install_script 'script/perlbloat';

WriteAll;
