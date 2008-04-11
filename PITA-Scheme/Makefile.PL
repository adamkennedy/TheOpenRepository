use strict;
use inc::Module::Install;

name           'PITA-Scheme';
all_from       'lib/PITA/Scheme.pm';
test_requires 'Module::Build'    => '0.28';
requires       'Carp'             => 0;
requires       'File::Temp'       => 0;
requires       'File::Spec'       => '0.80';
requires       'File::pushd'      => '0.99';
requires       'File::Which'      => '0.05';
requires       'IPC::Run3'        => '0.036';
requires       'Params::Util'     => '0.23';
requires       'Archive::Extract' => '0.18';
requires       'Process'          => '0.16';
requires       'PITA::XML'        => '0.40';
test_requires 'Cwd'              => 0;
test_requires 'Test::More'       => '0.47';
test_requires 'File::Remove'     => '0.34';

WriteAll;
