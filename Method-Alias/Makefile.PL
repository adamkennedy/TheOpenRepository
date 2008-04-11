use inc::Module::Install;

name           'Method-Alias';
all_from       'lib/Method/Alias.pm';
test_requires 'Test::More' => '0.47';
test_requires 'File::Spec' => '0.82';

WriteAll;
