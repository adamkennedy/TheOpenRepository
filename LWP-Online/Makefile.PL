use strict;
use inc::Module::Install;

name           'LWP-Online';
all_from       'lib/LWP/Online.pm';
requires       'Carp'        => 0;
requires       'LWP::Simple' => 0;
test_requires 'Test::More' => '0.42';

WriteAll;
