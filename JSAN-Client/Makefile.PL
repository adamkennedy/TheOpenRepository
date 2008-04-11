use strict;
use inc::Module::Install;

name           'JSAN-Client';
all_from       'lib/JSAN/Client.pm';
requires       'Scalar::Util'          => '1.11';
requires       'Params::Util'          => '0.14';
requires       'File::Spec'            => '0.80';
requires       'File::Path'            => '1.06';
requires       'File::HomeDir'         => '0.63';
requires       'Config::Tiny'          => '2.02';
requires       'Digest::MD5'           => '2.33';
requires       'URI'                   => 0 ;
requires       'URI::ToDisk'           => '1.08';
requires       'LWP::Simple'           => '1.41';
requires       'LWP::Online'           => '0.02';
requires       'Class::DBI'            => '3.000011';
requires       'DBD::SQLite'           => '1.08';
requires       'Archive::Tar'          => '1.30';
requires       'Archive::Zip'          => '1.18';
requires       'YAML'                  => '0.39';
requires       'Algorithm::Dependency' => '1.101';
test_requires 'Test::More'            => '0.47';
test_requires 'File::Remove'          => '0.34';

WriteAll;
