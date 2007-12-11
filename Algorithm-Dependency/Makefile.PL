use strict;
use inc::Module::Install;

name            'Algorithm-Dependency';
all_from        'lib/Algorithm/Dependency.pm';
requires        'Params::Util'   => '0.06';
requires        'List::Util'     => '1.11';
build_requires  'Test::More'     => '0.47';
build_requires  'File::Spec'     => '0.80';
build_requires  'Test::ClassAPI' => '0.6';

WriteAll;
