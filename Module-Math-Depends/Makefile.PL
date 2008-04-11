use strict;
use inc::Module::Install;

name           'Module-Math-Depends';
all_from       'lib/Module/Math/Depends.pm';
requires       'Carp'         => 0;
requires       'version'      => '0.6701';
requires       'Params::Util' => '0.10';
test_requires 'Test::More'   => '0.42';

WriteAll;
