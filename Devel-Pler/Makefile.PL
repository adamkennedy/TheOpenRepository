use inc::Module::Install;

name           'Devel-Pler';
all_from       'bin/pler';
requires       'Exporter'     => 0;
requires       'File::Spec'   => '0.80';
build_requires 'Test::More'   => '0.47';
build_requires 'Test::Script' => '0.01';
install_script 'bin/pler';

WriteAll;
