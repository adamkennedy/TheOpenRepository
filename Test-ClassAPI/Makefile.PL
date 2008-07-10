use inc::Module::Install 0.76;

all_from      'lib/Test/ClassAPI.pm';
requires      'File::Spec'       => '0.83';
requires      'Class::Inspector' => '1.12';
requires      'Config::Tiny'     => '2.00';
requires      'Params::Util'     => '0.10';
test_requires 'Test::More'       => '0.47';

WriteAll;
