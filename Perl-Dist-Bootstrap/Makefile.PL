use strict;
use inc::Module::Install;

# Define metadata
name        'Perl-Dist-Bootstrap';
author      'Adam Kennedy <adamk@cpan.org>';
version     '0.01';
all_from    'lib/Perl/Dist/Bootstrap.pm';
requires    'Perl::Dist' => '0.003';

WriteAll;
