use inc::Module::Install;

name           'JSAN-Client';
all_from       'lib/JSAN/Client.pm';
requires       'File::Spec'            => '0.80';
requires       'Scalar::Util'          => '1.11';
requires       'File::Path'            => '1.06';
requires       'File::HomeDir'         => '0.50';
requires       'Config::Tiny'          => '2.02';
requires       'URI'                   => 0 ;
requires       'HTML::Location'        => '0.07';
requires       'LWP::Simple'           => '1.41';
requires       'Class::DBI'            => '3.000011';
requires       'DBD::SQLite'           => '1.08';
requires       'Archive::Tar'          => 0;
requires       'Archive::Zip'          => 0;
requires       'YAML'                  => '0.39';
requires       'Algorithm::Dependency' => '1.02';
build_requires 'Test::More'            => '0.47';
build_requires 'File::Remove'          => '0.22';

WriteAll;
