use inc::Module::Install 0.77;

all_from       'lib/Perl/Dist/Parrot.pm';
requires       'Perl::Dist' => '1.10';
build_requires 'Test::More' => '0.80';

WriteAll;
