use strict;
use inc::Module::Install;

name     'Mirror-YAML';
all_from 'lib/Mirror/YAML.pm';
requires 'Params::Util' => '0.10';
requires 'YAML::Tiny'   => '1.00';
requires 'URI'          => 0;

WriteAll;
