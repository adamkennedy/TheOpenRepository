use inc::Module::Install;

name           'File-PathList';
all_from       'lib/File/PathList.pm';
requires       'File::Spec'      => '0.80';
requires       'Params::Util'    => '0.05';
build_requires 'Test::More'      => '0.47';

auto_install;
WriteAll;
