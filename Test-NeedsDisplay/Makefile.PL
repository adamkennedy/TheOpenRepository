use inc::Module::Install;

name           'Test-NeedsDisplay';
all_from       'lib/Test/NeedsDisplay.pm';
requires       'File::Spec'       => '0.80';
build_requires 'Test::More'       => '0.47';

auto_install;
WriteAll;
