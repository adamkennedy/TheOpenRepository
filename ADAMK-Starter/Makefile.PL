use strict;
use inc::Module::Install;

name           'ADAMK-Starter';
all_from       'lib/ADAMK/Starter.pm';
requires       'Carp'                => 0;
requires       'File::Spec'          => '0.80';
requires       'Params::Util'        => '0.20';
requires       'Object::Tiny'        => '1.01';
requires       'Date::Tiny'          => '0.02';
requires       'File::Flat'          => '1.00';
build_requires 'Test::More'          => '0.42';
build_requires 'Test::Script'        => '1.02';
build_requires 'Test::File::Cleaner' => '0.03';
install_script 'bin/adamk-starter';

WriteAll;
