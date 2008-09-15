use inc::Module::Install 0.77;

all_from      'lib/Module/Updated.pm';
requires      'PPI' => '1.201';
test_requires 'Test::More' => '0.42';

WriteAll;
