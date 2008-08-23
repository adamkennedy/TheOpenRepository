use inc::Module::Install 0.77;

all_from      'lib/Test/SubCalls.pm';
requires      'Test::More'            => '0.60';
requires      'File::Spec'            => '0.80';
requires      'Hook::LexWrap'         => '0.20';
test_requires 'Test::Builder::Tester' => '1.02';

WriteAll;
