use inc::Module::Install 0.76;

name           'LV-Network';
author         'Adam Kennedy <adam@phase-n.com>';
license        'perl';
abstract       'Provides a simple abstraction over both ssh and scp functions';
all_from       'lib/Net/SSH/Simple.pm';
requires       'Carp'                => 0;
requires       'IO::File'            => '1.14';
requires       'File::Spec'          => '0.80';
requires       'File::Temp'          => '0.18';
requires       'File::Slurp'         => '9999.13';
requires       'Params::Util'        => '0.20';
requires       'Time::HiRes'         => '1.9707';
requires       'Validate::Net'       => '0.5';
requires       'Net::Ping'           => '2.31';
requires       'Net::SSH'            => '0.08';
requires       'Net::SCP'            => '0.07';
requires       'ExtUtils::MM_Unix'   => '1.52';
build_requires 'Test::More'          => '0.42';
build_requires 'Test::File::Cleaner' => '0.03';

# Make sure we have commands we need
requires_external_bin 'ssh';
requires_external_bin 'scp';

WriteAll;
