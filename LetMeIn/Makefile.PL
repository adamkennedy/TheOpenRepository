use strict;
use inc::Module::Install;

name           'TinyAuth';
all_from       'lib/TinyAuth.pm';
requires       'Carp'                     => 0;
requires       'FindBin'                  => 0;
requires       'File::Spec'               => '0.80';
requires       'Scalar::Util'             => '1.15';
requires       'CGI'                      => '3.00';
requires       'CGI::Cookie'              => 0;
requires       'YAML::Tiny'               => '1.12';
requires       'String::MkPasswd'         => '0.02';
requires       'Authen::Htpasswd'         => '0.15';
requires       'Email::MIME'              => '1.859';
requires       'Email::MIME::Creator'     => '1.453';
requires       'Email::Send'              => '2.182';
requires       'Module::CGI::Install'     => '0.04';
build_requires 'Test::More'               => '0.42';
build_requires 'IPC::Run3'                => '0.034';
build_requires 'File::Copy'               => 0;
build_requires 'File::Remove'             => '0.37';
install_script 'script/tinyauth';

WriteAll;
