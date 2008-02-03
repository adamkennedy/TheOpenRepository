use strict;
use inc::Module::Install;

name          'Perl-Dist-Glutamate';
author        'Steffen Mueller <smueller@cpan.org>';
license       'perl';
version       '0.01';
all_from      'lib/Perl/Dist/Glutamate.pm';
requires      'Perl::Dist' => '0.90'; 
requires      'File::ShareDir' => '0'; 

install_share;

WriteAll;
