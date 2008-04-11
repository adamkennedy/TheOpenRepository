use strict;
use inc::Module::Install;

name           'Lingua-EN-VarCon';
all_from       'lib/Lingua/EN/VarCon.pm';
requires       'File::ShareDir'   => '0.03';
test_requires 'File::Spec'       => '0.80';
test_requires 'Test::More'       => '0.47';
install_share;

WriteAll;
