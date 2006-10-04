use strict;
use inc::Module::Install;

name           'Test-POE-Stopping';
all_from       'lib/Test/POE/Stopping.pm';
requires       'Carp'                  => 0;
requires       'Exporter'              => 0;
requires       'POE'                   => '0.38';
requires       'POE::API::Peek'        => '1.0594';
build_requires 'Test::More'            => '0.62';
build_requires 'Test::Builder'         => '0.32';
build_requires 'Test::Builder::Tester' => '1.02';

WriteAll;
