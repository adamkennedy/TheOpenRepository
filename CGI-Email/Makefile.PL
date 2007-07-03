use strict;
use inc::Module::Install;

name           'CGI-Email';
all_from       'lib/CGI/Email.pm';
requires       'CGI'          => '3.00';
requires       'Email::Send'  => 0;
requires       'CGI::Install' => 0;
build_requires 'Test::More'   => '0.42';

WriteAll;
