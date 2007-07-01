use strict;
use inc::Module::Install;

name           'Process-Backgroundable';
all_from       'lib/Process/Backgroundable.pm';
requires       'Storable'          => '2.14';
requires       'File::Temp'        => 0;
requires       'IPC::Run3'         => '0.034';
requires       'Process::Storable' => '0.20';
build_requires 'File::Spec'        => '0.80';
build_requires 'Test::More'        => '0.42';
build_requires 'File::Remove'      => '0.36';

WriteAll;
