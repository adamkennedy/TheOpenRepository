use strict;
use inc::Module::Install;

name           'CGI-Install-Demo';
all_from       'lib/CGI/Install/Demo.pm';
requires       'CGI'          => '3.00';
requires       'CGI::Install' => '0.02';
test_requires 'Test::More'   => '0.42';
install_script 'script/cgi_install_demo';

WriteAll;
