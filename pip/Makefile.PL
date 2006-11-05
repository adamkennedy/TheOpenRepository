use strict;
use inc::Module::Install;

name           'Module-Plan-Base';
all_from       'lib/Module/Plan/Base.pm';
requires       'Carp'           => 0;
requires       'CPAN'           => '1.76';
requires       'File::Spec'     => '0.80';
requires       'File::Which'    => '0.05';
requires       'File::Basename' => 0;
requires       'Getopt::Long'   => 0;
requires       'Params::Util'   => '0.10';
requires       'Test::More'     => '0.42';
requires       'CPAN::Inject'   => '0.01';
build_requires 'Test::Script'   => '1.02';
install_script 'bin/pip';

WriteAll;
