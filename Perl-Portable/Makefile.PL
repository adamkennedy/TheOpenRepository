use inc::Module::Install;

all_from       'lib/Perl/Portable.pm';
requires       'List::Util'   => '1.19';
requires       'File::Spec'   => '0.80';
requires       'Params::Util' => '0.31';
requires       'YAML::Tiny'   => '1.29';
requires       'Object::Tiny' => '1.04';
test_requires  'Test::More'   => '0.42';

WriteAll;
