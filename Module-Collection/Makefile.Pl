use strict;
use inc::Module::Install;

name           'Module-Collection';
all_from       'lib/Module/Collection.pm';
requires       'Carp'                  => 0;
requires       'File::Find::Rule'      => 0;
requires       'Params::Util'          => '0.10';
requires       'Module::Math::Depends' => '0.01';
requires       'Module::Inspector'     => '0.02';
build_requires 'Test::More'            => '0.42';

WriteAll;

