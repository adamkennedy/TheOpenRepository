use strict;
use inc::Module::Install;

name     'Perl-Dist-Downloads';
all_from 'lib/Perl/Dist/Downloads.pm';
requires 'File::ShareDir' => '0.05';

install_share;

WriteAll;
