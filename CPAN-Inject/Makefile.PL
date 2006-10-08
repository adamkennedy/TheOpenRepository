use strict;
use inc::Module::Install;

name           'CPAN-Inject';
all_from       'lib/CPAN/Inject.pm';
requires       'File::Spec'      => '0.80';
requires       'File::stat'      => '1.00';
requires       'File::chmod'     => '0.30';
requires       'File::Path'      => '1.00';
requires       'File::Copy'      => '2.02';
requires       'File::Basename'  => '2.6';
requires       'Params::Util'    => '0.10';
requires       'CPAN'            => '1.87';
requires       'CPAN::Checksums' => '1.05';
build_requires 'Test::More'      => '0.42';
build_requires 'Test::Script'    => '0.01';
build_requires 'File::Remove'    => '0.22';
install_script 'bin/cpaninject';

WriteAll;
