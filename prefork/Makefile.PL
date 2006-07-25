use inc::Module::Install;

name           'prefork';
all_from       'lib/prefork.pm';
requires       'Scalar::Util' => '1.10';
build_requires 'Test::More'   => '0.47';
build_requires 'File::Spec'   => '0.80';

WriteAll;
