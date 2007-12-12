use strict;
use inc::Module::Install;

name                  'VCS-CSync';
all_from              'lib/VCS/CSync.pm';
requires              'Params::Util' => '0.05';
requires              'Config::Tiny' => '2.01';
requires              'File::Flat'   => '0.93';
requires              'Getopt::Long' => 0;
requires              'File::Spec'   => '0.82';
build_requires        'Test::More'   => '0.47';
requires_external_bin 'cvs';
requires_external_bin 'chmod';
requires_external_bin 'cd';
requires_external_bin 'export';
install_script        'script/csync';

WriteAll;

