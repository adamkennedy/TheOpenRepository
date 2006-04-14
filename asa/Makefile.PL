use inc::Module::Install;

name           'asa';
all_from       'lib/asa.pm';
requires       'Carp'       => 0;
requires       'base'       => 0;
build_requires 'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

auto_install;
WriteAll;
