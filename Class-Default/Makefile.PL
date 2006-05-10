use inc::Module::Install;

name           'Class-Default';
all_from       'lib/Class/Default.pm';
build_requires 'Test::More'       => '0.47';
build_requires 'File::Spec'       => '0.82';

WriteAll;
