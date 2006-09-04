use inc::Module::Install;

name           'PPI-Tester';
all_from       'lib/PPI/Tester.pm';
requires       'PPI'               => '1.117';
requires       'Wx'                => '0.54';
requires       'Wx::CheckLauncher' => '0.01';
build_requires 'File::Spec'        => '0.80';
build_requires 'Test::More'        => '0.47';
install_script 'bin/ppitester';

WriteAll;
