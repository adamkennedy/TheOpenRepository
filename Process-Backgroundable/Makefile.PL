use strict;
use inc::Module::Install;

name           'Process-Backgroundable';
all_from       'lib/Process/Backgroundable.pm';
requires       'Storable'          => '2.14';
requires       'File::Temp'        => 0;
requires       'IPC::Run3'         => '0.034';
requires       'Process::Storable' => '0.20';
test_requires 'File::Spec'        => '0.80';
test_requires 'Test::More'        => '0.42';
test_requires 'File::Remove'      => '0.36';

WriteAll;
