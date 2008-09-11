use inc::Module::Install;

name          'CPAN-Cache';
all_from      'lib/CPAN/Cache.pm';
requires      'IO::File'       => '1.2301';
requires      'File::Spec'     => '0.80';
requires      'File::HomeDir'  => '0.54';
requires      'Params::Util'   => '0.10';
requires      'URI::ToDisk'    => '1.09';
requires      'LWP::Simple'    => 0;
test_requires 'Test::More'     => '0.47';
test_requires 'File::Spec'     => '0.80';

WriteAll;
