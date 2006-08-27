use inc::Module::Install;

name           'Date-Tiny';
all_from       'lib/Date/Tiny.pm';
build_requires 'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

WriteAll;
