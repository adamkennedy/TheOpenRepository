use inc::Module::Install;

name           'Acme-BadExample';
perl_version   '5.005';
all_from       'lib/Acme/BadExample.pm';
build_requires 'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

WriteAll;
