use inc::Module::Install;

name           'Class-Default';
all_from       'lib/Class/Default.pm';
test_requires 'Test::More'       => '0.47';

WriteAll;
