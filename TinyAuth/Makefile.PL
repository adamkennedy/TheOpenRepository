use strict;
use inc::Module::Install;

name           'TinyAuth';
all_from       'lib/TinyAuth.pm';
requires       'Carp'                     => 0;
requires       'FindBin'                  => 0;
requires       'CGI'                      => '3.00';
requires       'CGI::Cookie'              => 0;
requires       'Params::Util'             => '0.21';
requires       'Object::Tiny'             => '1.02';
requires       'YAML::Tiny'               => '1.12';
requires       'String::MkPasswd'         => '0.02';
requires       'Module::CGI::Install'     => '0.04';
requires       'Authen::Htpasswd'         => '0.15';
requires       'Email::Send'              => '2.182';
requires       'Email::Stuff'             => '2.05';
build_requires 'Test::More'               => '0.42';
build_requires 'Test::Script'             => '1.02';
build_requires 'Test::LongString'         => '0.11';
build_requires 'File::Copy'               => 0;
build_requires 'File::Remove'             => '0.37';
install_script 'script/tinyauth';

WriteAll;
