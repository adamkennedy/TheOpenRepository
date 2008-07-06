use inc::Module::Install;

all_from      'lib/JSAN/Client.pm';
requires      'Scalar::Util'          => '1.11';
requires      'Params::Util'          => '0.14';
requires      'File::Spec'            => '0.80';
requires      'File::Path'            => '1.06';
requires      'File::HomeDir'         => '0.69';
requires      'Config::Tiny'          => '2.12';
requires      'Digest::MD5'           => '2.33';
requires      'URI'                   => 0 ;
requires      'URI::ToDisk'           => '1.08';
requires      'LWP::Simple'           => '1.41';
requires      'LWP::Online'           => '0.03';
requires      'Class::DBI'            => '3.0.17';
requires      'DBD::SQLite'           => '1.08';
requires      'Archive::Tar'          => '1.30';
requires      'Archive::Zip'          => '1.18';
requires      'Algorithm::Dependency' => '1.106';
test_requires 'Test::More'            => '0.47';
test_requires 'File::Remove'          => '1.40';

WriteAll;
