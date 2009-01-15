use inc::Module::Install 0.77;

all_from      'lib/ORDB/CPANTS.pm';
requires      'ORLite'         => '1.18';
requires      'ORLite::Mirror' => '0.09';
test_requires 'Test::More'     => '0.42';
test_requires 'LWP::Online'    => '1.07';

WriteAll;
