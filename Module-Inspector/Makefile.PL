use strict;
use inc::Module::Install;

name           'Module-Inspector';
all_from       'lib/Module/Inspector.pm';
requires       'Carp'                   => 0;
requires       'version'                => '0.6701';
requires       'File::Spec'             => '0.80';
requires       'File::Path'             => '1.06';
requires       'File::Temp'             => '0.17';
requires       'Params::Util'           => '0.17';
requires       'Archive::Extract'       => '0.12';
requires       'YAML::Tiny'             => '0.11';
requires       'File::Find::Rule'       => 0;
requires       'File::Find::Rule::VCS'  => '1.02';
requires       'File::Find::Rule::Perl' => 0;
requires       'PPI'                    => '1.118';
requires       'Module::Manifest'       => '0.01';
requires       'Module::Math::Depends'  => '0.01';
build_requires 'Test::More'             => '0.47';

WriteAll;
