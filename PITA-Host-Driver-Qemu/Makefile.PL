use inc::Module::Install;

name     'PITA-Host-Driver-Qemu';
all_from 'lib/PITA/Host/Driver/Qemu.pm';
requires       'Carp'         => 0;
requires       'File::Spec'   => '0.80';
requires       'File::Copy'   => 
requires       'File::Temp'   => '0.15';
requires       'File::Which'  => '0.05';
requires       'Config::Tiny' => '2.00';
requires       'Params::Util' => '0.07';
requires       'PITA::Report' => '0.03';
build_requires 'Test::More'   => '0.47';

auto_install;
WriteAll;
