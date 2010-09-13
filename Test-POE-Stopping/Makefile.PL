use inc::Module::Install 1.00;

all_from      'lib/Test/POE/Stopping.pm';
requires_from 'lib/Test/POE/Stopping.pm';
requires      'POE::API::Peek' => '1.34';

WriteAll;
