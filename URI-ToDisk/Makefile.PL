use strict;
use inc::Module::Install;

name           'URI-ToDisk';
all_from       'lib/URI/ToDisk.pm';
requires       'Clone'           => '0.21';
requires       'List::Util'      => '1.11';
requires       'URI'             => 0;
requires       'Params::Util'    => '0.10';
test_requires 'Test::More'      => '0.47';
test_requires 'File::Spec'      => '0.80';

WriteAll;
