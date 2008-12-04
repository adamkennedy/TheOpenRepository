use inc::Module::Install 0.77;

all_from       'lib/Perl/Dist/Parrot.pm';
requires       'Perl::Dist'   => '1.11';
build_requires 'Test::More'   => '0.80';
build_requires 'File::Spec'   => 0;
build_requires 'File::Path'   => 0;
build_requires 'File::Remove' => 0;

WriteAll;
