use strict;
use inc::Module::Install;

name           'File-LocalizeNewlines';
all_from       'lib/File/LocalizeNewlines.pm';
requires       'FileHandle'       => 0;
requires       'Getopt::Long'     => 0;
requires       'File::Spec'       => '0.80';
requires       'File::Remove'     => '0.34';
requires       'File::Slurp'      => '9999.04';
requires       'File::Find::Rule' => '0.20';
requires       'Class::Default'   => '1.0';
requires       'Params::Util'     => '0.10';
build_requires 'Test::More'       => '0.42';
install_script 'bin/localizenewlines';

WriteAll;
