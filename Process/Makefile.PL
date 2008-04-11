use strict;
use inc::Module::Install;

name           'Process';
all_from       'lib/Process.pm';
requires       'IO::Handle'   => 0;
requires       'IO::File'     => 0;
requires       'IO::String'   => 0;
requires       'Storable'     => '2.14';
requires       'YAML::Tiny'   => '1.26';
requires       'Scalar::Util' => '1.17';
requires       'Params::Util' => '0.10';
requires       'File::Temp'   => 0;
requires       'IPC::Run3'    => '0.034';
requires       'Probe::Perl'  => '0.01';
test_requires 'File::Spec'   => '0.80';
test_requires 'File::Remove' => '0.34';
test_requires 'Test::More'   => '0.47';

WriteAll;
