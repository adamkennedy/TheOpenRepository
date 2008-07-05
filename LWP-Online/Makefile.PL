use inc::Module::Install 0.76;

all_from      'lib/LWP/Online.pm';
requires      'URI'         => 0;
requires      'LWP::Simple' => 0;
test_requires 'Test::More'  => '0.42';

WriteAll;
