use inc::Module::Install;

name           'Test-SubCalls';
all_from       'lib/Test/SubCalls.pm';
requires       'Test::More'            => '0.60';
requires       'File::Spec'            => '0.80';
requires       'Hook::LexWrap'         => '0.20';

# We need the updated non-broken Test-Simple
build_requires 'Test::Builder::Tester' => '1.02';

WriteAll;
