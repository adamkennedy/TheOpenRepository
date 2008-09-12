use inc::Module::Install 0.77;

all_from      'lib/Debug/Eval.pm';
requires      'File::Temp' => '0.20';
test_requires 'Test::More' => '0.42';

WriteAll;
