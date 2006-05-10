use inc::Module::Install;

name           'Identifier';
all_from       'lib/Identifier.pm';
requires       'Carp'       => 0;
requires       'base'       => 0;
requires       'URI'        => '1.33';
build_requires 'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

WriteAll;
