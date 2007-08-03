use strict;
use inc::Module::Install;

name           'Imager-Search';
all_from       'lib/Imager/Search.pm';
requires       'Carp'                => 0;
requires       'IO::File'            => 0;
requires       'Params::Util'        => '0.26';
requires       'Object::Tiny'        => '1.01';
requires       'Imager'              => '0.59';
build_requires 'Test::More'          => '0.42';
build_requires 'Test::File::Cleaner' => 0;

WriteAll;
