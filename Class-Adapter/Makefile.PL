use inc::Module::Install 0.77;

all_from      'lib/Class/Adapter.pm';
requires      'Scalar::Util' => '1.10';
test_requires 'Test::More'   => '0.47';

WriteAll;
