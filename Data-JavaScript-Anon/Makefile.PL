use inc::Module::Install;

name          'Data-JavaScript-Anon';
all_from      'lib/Data/JavaScript/Anon.pm';
requires      'Params::Util' => '0.10';
test_requires 'File::Spec'   => '0.82';
test_requires 'Test::More'   => '0.47';

WriteAll;
