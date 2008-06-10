use inc::Module::Install;

all_from      'lib/POE/Declare.pm';
requires      'Carp';
requires      'Scalar::Util'     => '1.17';
requires      'Params::Util'     => '0.33';
requires      'Class::Inspector' => '1.20';
requires      'IO::File'         => '1.14';
requires      'POE'              => '1.0002';
test_requires 'Test::More'       => '0.80';

WriteAll;
