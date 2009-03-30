use inc::Module::Install 0.79;

name          'Acme-BadExample';
perl_version  '5.005';
version       '1.01';
all_from      'lib/Acme/BadExample.pm';
test_requires 'File::Spec' => '0.80';
test_requires 'Test::More' => '0.47';

WriteAll;
