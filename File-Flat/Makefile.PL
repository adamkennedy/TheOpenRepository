use strict;
use inc::Module::Install;

name           'File-Flat';
all_from       'lib/File/Flat.pm';
requires       'Cwd'                   => 0;
requires       'prefork'               => '0.02';
requires       'File::Spec'            => '0.85';    # Faster and featureful
requires       'File::Copy'            => 0;
requires       'File::Copy::Recursive' => '0.28';
requires       'File::Slurp'           => '9999.04';
requires       'File::Remove'          => '0.21';    # Required for File::Spec support
requires       'File::Temp'            => '0.14';    # Some bugs below 0.12 could matter
requires       'IO::File'              => 0;
build_requires 'Test::More'            => '0.47';
build_requires 'Test::ClassAPI'        => '1.02';
build_requires 'File::Find'            => 0;         # Avoid use of system chmod -R in test script

WriteAll;
