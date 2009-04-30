use inc::Module::Install;
include 'Module::AutoInstall';

name 'Aspect';
all_from 'lib/Aspect.pm';
perl_version '5.008002';

requires 'Benchmark::Timer';
requires 'Devel::Symdump';
requires 'Test::Class';

test_requires 'Test::More' => '0.70';
extra_tests;

auto_install;
auto_include;
WriteAll;
