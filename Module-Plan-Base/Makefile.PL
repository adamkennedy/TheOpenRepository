use strict;
use inc::Module::Install;

name           'Module-Plan-Base';
all_from       'lib/Module/Plan/Base.pm';
requires       'Carp'           => 0;
requires       'File::Spec'     => '0.80';
requires       'File::Basename' => 0;
requires       'Params::Util'   => '0.10';
requires       'Test::More'     => '0.42';
build_requires 'Test::Script'   => '0.01';
install_script 'bin/pip';

WriteAll;

