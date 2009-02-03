use inc::Module::Install 0.79;

all_from      'lib/ORDB/CPANTesters.pm';
requires      'ORLite'         => '1.19';
requires      'ORLite::Mirror' => '1.11';
test_requires 'Test::More'     => '0.42';
test_requires 'LWP::Online'    => '1.07';

WriteAll;
