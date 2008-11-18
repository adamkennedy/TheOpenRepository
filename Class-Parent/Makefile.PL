use inc::Module::Install 0.77;

all_from       'lib/Class/Parent.pm';
requires       'Scalar::Util' => '1.19';
build_requires 'Test::More'   => '0.86';

WriteAll;
