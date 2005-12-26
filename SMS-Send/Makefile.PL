use inc::Module::Install;

name           'SMS-Send';
all_from       'lib/SMS/Send.pm';
requires       'Module::Pluggable' => 0;
build_requires 'File::Spec'        => '0.80';
build_requires 'Test::More'        => '0.47';

auto_install;
WriteAll;
