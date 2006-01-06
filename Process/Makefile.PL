use inc::Module::Install;

name           'Process';
all_from       'lib/Process.pm';
requires       'Config::Tiny'      => '2.00';
requires       'Storable'          => '2.14';
requires       'Params::Util'      => '0.07';
build_requires 'File::Spec'        => '0.80';
build_requires 'Test::More'        => '0.47';

auto_install;
WriteAll;
