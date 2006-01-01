use inc::Module::Install;

name           'PITA-Scheme';
all_from       'lib/PITA/Scheme.pm';
requires       'Carp'             => 0;
requires       'IPC::Cmd'         => '0.24';
requires       'IPC::Run'         => '0.78';
requires       'IPC::Open3'       => 0;
requires       'File::Spec'       => '0.80';
requires       'File::Temp'       => 0;
requires       'Params::Util'     => '0.07';
requires       'Config::Tiny'     => '2.04';
requires       'Archive::Extract' => '0.07';
requires       'PITA::Report'     => '0.05';
build_requires 'Test::More'       => '0.47';
build_requires 'File::Remove'     => '0.22';

auto_install;
WriteAll;
