use inc::Module::Install;

name           'JSAN-Mini';
all_from       'lib/JSAN/Mini.pm';
requires       'JSAN::Client' => '0.14';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.47';
install_script 'bin/minijsan';

WriteAll;
