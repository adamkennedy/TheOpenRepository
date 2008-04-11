use strict;
use inc::Module::Install;

name           'CGI-Email';
all_from       'lib/CGI/Email.pm';
requires       'CGI'          => '3.00';
requires       'Email::Send'  => '2.183';
requires       'CGI::Install' => 0;
test_requires 'Test::More'   => '0.42';

WriteAll;
