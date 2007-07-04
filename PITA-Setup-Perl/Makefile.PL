use strict;
use inc::Module::Install;

name                  'PITA-Setup-Perl';
all_from              'bin/pita_setup_perl';
requires              'Getopt::Long'     => 0;
requires_external_bin 'wget';
requires_external_bin 'md5sum';

WriteAll;
