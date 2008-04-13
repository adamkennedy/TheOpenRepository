use inc::Module::Install;

all_from       'lib/Perl/Portable.pm';
requires       'YAML::Tiny' => 0;
build_requires 'File::Spec' => '0.80';
build_requires 'Test::More' => '0.42';

WriteAll;
