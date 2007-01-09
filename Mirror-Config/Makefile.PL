use strict;
use inc::Module::Install;

name     'Mirror-Config';
all_from 'lib/Mirror/Config.pm';
requires 'Params::Util' => '0.10';
requires 'YAML::Tiny'   => '0.01';
requires 'URI'          => 0;

WriteAll;
