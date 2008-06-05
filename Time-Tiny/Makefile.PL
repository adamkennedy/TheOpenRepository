use inc::Module::Install;

name          'Time-Tiny';
all_from      'lib/Time/Tiny.pm';
requires      'Carp';
requires      'overload';
test_requires 'Test::More' => '0.47';

WriteAll;
