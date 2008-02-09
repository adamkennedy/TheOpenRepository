use strict;
use inc::Module::Install;

name           'CPAN-Metrics';
all_from       'lib/CPAN/Metrics.pm';
requires       'Carp'                => 0;
requires       'Getopt::Long'        => 0;
requires       'File::HomeDir'       => '0.06';
requires       'Perl::Metrics'       => '0.05';
requires       'CPAN::Mini::Extract' => '0.12';
install_script 'bin/cpanmetrics';

WriteAll;
