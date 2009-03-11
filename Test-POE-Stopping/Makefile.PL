use inc::Module::Install 0.79;

all_from      'lib/Test/POE/Stopping.pm';
requires      'POE'            => '1.003';
requires      'POE::API::Peek' => '1.0594';
test_requires 'Test::More'     => '0.62';
test_requires 'Test::Builder'  => '0.64';

WriteAll;
