use strict;
use inc::Module::Install;

name     'Mirror-Config';
all_from 'lib/Mirror/Config.pm';
requires 'YAML::Tiny' => '0.01';

WriteAll;
