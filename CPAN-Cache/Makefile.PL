use inc::Module::Install;

name           'CPAN-Index';
all_from       'lib/CPAN/Index.pm';
requires       'Carp'           => 0;
requires       'File::Path'     => 0;
requires       'IO::File'       => 0;
requires       'File::Spec'     => '0.80'
requires       'File::HomeDir'  => '0.54';
requires       'Params::Util'   => '0.10';
requires       'URI::ToDisk'    => '1.09';
requires       'LWP::Simple'    => 0;
build_requires 'Test::More'     => '0.47';
build_requires 'File::Spec'     => '0.80';

WriteAll;
