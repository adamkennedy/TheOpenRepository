use strict;
use inc::Module::Install;

# Define metadata
name        'Perl-Dist-Vanilla';
author      'Adam Kennedy <adamk@cpan.org>';
license     'perl';
all_from    'lib/Perl/Dist/Vanilla.pm';

requires    'Perl::Dist' => '0.30'; 

WriteAll;
