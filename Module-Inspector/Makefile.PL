use inc::Module::Install;

name           'Module-Inspector';
all_from       'lib/Module/Inspector.pm';
requires       'Carp'                   => 0;
requires       'File::Spec'             => '0.80';
requires       'File::Path'             => '1.08';
requires       'File::Temp'             => '0.17';
requires       'Params::Util'           => '0.17';
requires       'Archive::Extract'       => '0.12';
requires       'YAML::Tiny'             => '0.10';
requires       'File::Find::Rule'       => 0;
requires       'File::Find::Rule::VCS'  => '1.02';
requires       'File::Find::Rule::Perl' => 0;
requires       'PPI'                    => '1.118';
build_requires 'Test::More'             => '0.47';

WriteAll;
