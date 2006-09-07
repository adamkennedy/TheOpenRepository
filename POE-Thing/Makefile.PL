use inc::Module::Install;

name           'POE-Thing';
all_from       'lib/POE/Thing.pm';
requires       'Carp'             => 0;
requires       'Scalar::Util'     => '1.17';
requires       'Params::Util'     => '0.17';
requires       'Class::Inspector' => '1.12';
requires       'IO::File'         => 
requires       'POE'              => '0.3601';
build_requires 'Test::More'       => '0.47';

WriteAll;
