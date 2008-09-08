use inc::Module::Install 0.77;

all_from      'lib/Mirror/YAML.pm';
requires      'Params::Util'      => '0.25';
requires      'Parse::CPAN::Meta' => '0.03';
requires      'URI'               => '1.28';
requires      'Time::HiRes'       => 0;
requires      'Time::Local'       => '1.13';
requires      'LWP::Simple'       => 0;
test_requires 'Test::More'        => '0.42';
test_requires 'File::Temp'        => '0.19';
test_requires 'LWP::Online'       => '1.07';

WriteAll;
