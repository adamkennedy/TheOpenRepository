use inc::Module::Install 0.80;

all_from      'lib/Algorithm/Dependency/MapReduce.pm';
requires      'Algorithm::Dependency' => '1.108';
test_requires 'Test::More'            => '0.42';

WriteAll;
