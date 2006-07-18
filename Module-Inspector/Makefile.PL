use inc::Module::Install;

name           'Module-Inspector';
all_from       'lib/Module/Inspector.pm';
requires       'Carp'       => 0;
requires       'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

1;
