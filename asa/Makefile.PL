use inc::Module::Install;

name          'asa';
all_from      'lib/asa.pm';
requires      'base'       => 0;
test_requires 'File::Spec' => '0.80';
test_requires 'Test::More' => '0.47';

WriteAll;
