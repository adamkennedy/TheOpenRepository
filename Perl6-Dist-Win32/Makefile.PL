use inc::Module::Install 0.76;

all_from       'lib/Perl6/Dist/Win32.pm';
requires       'Perl::Dist' => '1.04';
build_requires 'Test::More' => '0.47';

WriteAll;
