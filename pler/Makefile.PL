use inc::Module::Install;

name           'pler';
all_from       'lib/pler.pm';
requires       'Exporter'         => 0;
requires       'File::Spec'       => '0.80';
requires       'File::Which'      => '0.05';
requires       'File::Find::Rule' => '0.20';
build_requires 'Test::More'       => '0.47';
build_requires 'Test::Script'     => '0.01';
install_script 'bin/pler';

WriteAll;
