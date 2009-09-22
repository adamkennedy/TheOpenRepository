use inc::Module::Install 0.91;

all_from      'lib/JSAN/Client.pm';
requires      'ORLite'          => '1.25';
requires      'ORLite::Mirror'  => '1.16';
requires      'Digest::MD5'     => '2.33';
requires      'LWP::Simple'     => '1.41';
requires      'LWP::Online'     => '0.03';
requires      'File::Spec'      => '0.80';
requires      'File::Path'      => '1.06';
requires      'File::HomeDir'   => '0.69';
requires      'URI'             => '0';
requires      'URI::ToDisk'     => '1.08';
test_requires 'Test::More'      => '0.47';
test_requires 'File::Remove'    => '1.40';

WriteAll;

#requires      'Scalar::Util'          => '1.11';
#requires      'Params::Util'          => '0.14';
#requires      'Config::Tiny'          => '2.12';
#requires      'Archive::Tar'          => '1.30';
#requires      'Archive::Zip'          => '1.18';
#requires      'Algorithm::Dependency' => '1.106';
