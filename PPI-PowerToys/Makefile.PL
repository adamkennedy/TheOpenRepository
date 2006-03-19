use inc::Module::Install;

name           'Perl-PowerToys';
all_from       'lib/Perl/PowerToys.pm';
requires       'File::Spec'       => '0.80';
requires       'File::Find::Rule' => 0;
requires       'PPI'              => '1.109';
build_requires 'Test::More'       => '0.47';
install_script 'bin/ppichangeversion';

auto_install;
WriteAll;
