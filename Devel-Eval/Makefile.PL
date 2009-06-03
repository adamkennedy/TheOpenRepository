use inc::Module::Install 0.91;

all_from      'lib/Devel/Eval.pm';
test_requires 'Test::More' => '0.42';

WriteAll;
