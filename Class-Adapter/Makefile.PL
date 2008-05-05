use inc::Module::Install;

name           'Class-Adapter';
all_from       'lib/Class/Adapter.pm';
requires       'Carp'           => 0;
requires       'Scalar::Util'   => '1.10';
test_requires 'File::Spec'     => '0.80';
test_requires 'Test::More'     => '0.47';

WriteAll;
