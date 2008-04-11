use strict;
use inc::Module::Install;

name           'pler';
all_from       'lib/pler.pm';
requires       'Carp'             => 0;
requires       'blib'             => 0;
requires       'Cwd'              => '3.00';
requires       'File::Spec'       => '0.80';
requires       'File::Which'      => '0.05';
requires       'File::Find::Rule' => '0.20';
requires       'Getopt::Long'     => 0;
requires       'Probe::Perl'      => '0.01';
test_requires 'Test::More'       => '0.47';
test_requires 'Test::Script'     => '1.02';
install_script 'script/pler';

WriteAll;
