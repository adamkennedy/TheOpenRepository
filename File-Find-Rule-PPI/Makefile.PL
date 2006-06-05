use inc::Module::Install;

name           'File-Find-Rule-PPI';
all_from       'lib/File/Find/Rule/PPI.pm';
requires       'Params::Util'       => '0.10';
requires       'File::Find::Rule'   => '0.20';
requires       'PPI'                => '1.000';
build_requires 'File::Spec'         => '0.80';
build_requires 'Test::More'         => '0.47';

WriteAll;
