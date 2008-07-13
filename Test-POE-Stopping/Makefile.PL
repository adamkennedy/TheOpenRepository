use inc::Module::Install 0.76;

all_from      'lib/Test/POE/Stopping.pm';
requires      'Carp';
requires      'Exporter';
requires      'POE'            => '1.00';
requires      'POE::API::Peek' => '1.0594';
test_requires 'Test::More'     => '0.62';
test_requires 'Test::Builder'  => '0.64';

WriteAll;
