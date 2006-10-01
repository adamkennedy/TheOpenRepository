use inc::Module::Install;

name           'JSAN-Shell';
all_from       'lib/JSAN/Shell.pm';
requires       'Term::ReadLine' => '1.01';
requires       'Getopt::Long'   => '2.34';
requires       'JSAN::Client'   => '0.13';
build_requires 'File::Spec'     => '0.80';
build_requires 'Test::More'     => '0.47';
install_script 'bin/jsan2';

WriteAll;
