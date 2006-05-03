use inc::Module::Install;

name     'Test-Object';
all_from 'lib/Test/Object.pm';
requires 'Test::More' => '0.47';
requires 'File::Spec' => '0.82';

auto_install;
WriteAll;
