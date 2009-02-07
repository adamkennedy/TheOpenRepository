use inc::Module::Install 0.79;

all_from       'lib/Algorithm/Dependency.pm';
requires       'Params::Util'   => '0.31';
requires       'List::Util'     => '1.11';
test_requires  'Test::More'     => '0.47';
test_requires  'File::Spec'     => '0.80';
test_requires  'Test::ClassAPI' => '0.6';

WriteAll;
