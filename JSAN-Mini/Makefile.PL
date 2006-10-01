use inc::Module::Install;

name           'JSAN-Mini';
all_from       'lib/JSAN/Mini.pm';
requires       'JSAN::Client' => '0.12';
build_requires 'File::Spec'   => '0.80';
build_requires 'Test::More'   => '0.47';
install_script 'bin/minijsan';

WriteAll;
