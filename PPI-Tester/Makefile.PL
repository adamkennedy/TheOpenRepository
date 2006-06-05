use inc::Module::Install;

name           'PPI-Tester';
all_from       'lib/PPI/Tester.pm';
requires       'PPI'            => '1.114';
requires       'Wx'             => '0.49';
build_requires 'File::Spec'     => '0.80';
build_requires 'Test::More'     => '0.47';
install_script 'bin/ppitester';

WriteAll;
