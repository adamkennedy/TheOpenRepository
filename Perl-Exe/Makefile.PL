use strict;
use inc::Module::Install;

name           'Perl-Exe';
all_from       'lib/Perl/Exe.pm';
requires       'File::Spec'    => '0.80';
requires       'File::Basename' => 0;
requires       'IPC::Run3'     => 0;
build_requires 'Test::More'    => '0.47';

WriteAll;
