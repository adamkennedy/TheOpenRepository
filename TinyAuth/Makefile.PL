use strict;
use inc::Module::Install;

name           'TinyAuth';
all_from       'lib/TinyAuth.pm';
requires       'Carp'                     => 0;
requires       'FindBin'                  => 0;
requires       'CGI'                      => '3.00';
requires       'Params::Util'             => '0.21';
requires       'Object::Tiny'             => '1.02';
requires       'YAML::Tiny'               => '1.12';
requires       'Module::CGI::Install'     => '0.04';
requires       'Apache::Htpasswd::Shadow' => '0.02';
build_requires 'Test::More'               => '0.42';
build_requires 'Test::Script'             => '1.02';
build_requires 'Test::LongString'         => '0.11';
install_script 'script/tinyauth';

WriteAll;
