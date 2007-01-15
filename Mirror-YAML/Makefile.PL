use strict;
use inc::Module::Install;

name           'Mirror-YAML';
all_from       'lib/Mirror/YAML.pm';
requires       'Params::Util' => '0.10';
requires       'YAML::Tiny'   => '1.03';
requires       'URI'          => '1.28';
requires       'Time::Local'  => '1.13';
build_requires 'LWP::Online'  => '0.01';

WriteAll;
