use inc::Module::Install;

name           'File-Find-Rule-VCS';
all_from       'lib/File/Find/Rule/VCS.pm';
requires       'File::Find::Rule' => '0.20';
build_requires 'File::Spec'       => '0.82';
build_requires 'Test::More'       => '0.47';

auto_install;
WriteAll;
