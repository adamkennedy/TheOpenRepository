use strict;
use inc::Module::Install;

name           'Imager-Search';
all_from       'lib/Imager/Search.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
build_requires 'Test::More'   => '0.42';

WriteAll;
