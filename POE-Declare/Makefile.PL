use inc::Module::Install 0.79;

all_from      'lib/POE/Declare.pm';
requires      'Scalar::Util'        => winlike() ? '1.19' : '1.18';
requires      'List::Util'          => winlike() ? '1.19' : '1.18';
requires      'Params::Util'        => '0.38';
requires      'IO::File'            => '1.14';
requires      'Class::Inspector'    => '1.22';
requires      'Class::ISA'          => '0.33';
requires      'Class::XSAccessor'   => '0.14';
requires      'POE'                 => '1.003';
test_requires 'Test::More'          => '0.80';
test_requires 'Test::NoWarnings'    => '0.084';
test_requires 'Test::POE::Stopping' => '0.02';

WriteAll;
