use inc::Module::Install;

name           'Acme-Terror-AU';
perl_version   '5.005';
all_from       'lib/Acme/Terror/AU.pm';
test_requires 'File::Spec' => '0.80';
test_requires 'Test::More' => '0.47';

WriteAll;
