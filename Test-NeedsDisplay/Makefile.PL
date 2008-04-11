use inc::Module::Install;

name           'Test-NeedsDisplay';
all_from       'lib/Test/NeedsDisplay.pm';
requires       'File::Spec'       => '0.80';
test_requires 'Test::More'       => '0.47';

WriteAll;
