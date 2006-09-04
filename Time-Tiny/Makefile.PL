use inc::Module::Install;

name           'Time-Tiny';
all_from       'lib/Time/Tiny.pm';
build_requires 'Test::More' => '0.47';

WriteAll;
