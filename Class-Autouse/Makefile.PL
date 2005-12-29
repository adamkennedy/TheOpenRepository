use inc::Module::Install;

name           'Class-Autouse';
all_from       'lib/Class/Autouse.pm';
requires       'Carp'       => 0;
requires       'File::Spec' => '0.80';
requires       'List::Util' => '1.18';
build_requires 'Test::More' => '0.47';

auto_install;
WriteAll;
