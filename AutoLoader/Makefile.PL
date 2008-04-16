## This -*- perl -*- script writes the Makefile for AutoLoader
# You should read "perldoc perlmodinstall" for instructions on
#  how to install modules like this.

require 5.006_001;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME' => 'AutoLoader',
  'VERSION_FROM' => 'lib/AutoLoader.pm', # finds $VERSION
  'LICENSE' => 'perl',
  'PREREQ_PM' => {},
  'ABSTRACT_FROM' => 'lib/AutoLoader.pm',
  'AUTHOR' => 'Steffen Mueller <smueller@cpan.org>',
  'INSTALLDIRS' => 'perl',
);

__END__

