use strict;
use inc::Module::Install;

name           'JSAN-Shell';
all_from       'lib/JSAN/Shell.pm';
requires       'Term::ReadLine'       => '1.01';
requires       'Term::ReadLine::Perl' => '1.0302';
requires       'Getopt::Long'         => '2.34';
requires       'File::HomeDir'        => '0.63';
requires       'File::ShareDir'       => '0.05';
requires       'LWP::Online'          => '0.02';
requires       'Mirror::YAML'         => '0.02';
requires       'JSAN::Client'         => '0.16';
test_requires 'File::Spec'           => '0.80';
test_requires 'Test::More'           => '0.47';
install_script 'bin/jsan2';
install_share;

WriteAll;
