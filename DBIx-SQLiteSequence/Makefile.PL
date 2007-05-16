use strict;
use inc::Module::Install;

name           'DBIx-SQLiteSequence';
all_from       'lib/DBIx/SQLiteSequence.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
build_requires 'Test::More'   => '0.42';

WriteAll;
