use inc::Module::Install;

name           'SQL-Script';
all_from       'lib/SQL/Script.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.10';
test_requires 'Test::More'   => '0.42';
test_requires 'File::Spec'   => '0.80';

WriteAll;
