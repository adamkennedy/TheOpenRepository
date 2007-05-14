use strict;
use inc::Module::Install;

name           'CPAN-Mini-Extract';
all_from       'lib/CPAN/Mini/Extract.pm';
requires       'Carp'             => 0;
requires       'File::Basename'   => 0;
requires       'File::Path'       => 0;
requires       'File::Spec'       => '0.80';
requires       'File::Remove'     => '0.34';
requires       'File::Find::Rule' => '0.30';
requires       'List::Util'       => '1.15';
requires       'IO::File'         => 0;
requires       'IO::Zlib'         => '1.04';
requires       'Archive::Tar'     => '1.22';
requires       'Params::Util'     => '0.20';
requires       'CPAN::Mini'       => '0.550';
build_requires 'Test::More'       => '0.47';

WriteAll;
