use strict;
use inc::Module::Install;

name           'Email-Send-HTTP-Post';
all_from       'lib/Email/Send/HTTP/Post.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
test_requires 'Test::More'   => '0.42';

WriteAll;
