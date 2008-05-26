## This -*- perl -*- script writes the Makefile for lib.pm
# You should read "perldoc perlmodinstall" for instructions on
#  how to install modules like this.

require 5.006_001;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME' => 'lib',
  'VERSION' => '0.57',
  'LICENSE' => 'perl',
  'PREREQ_PM' => {},
  'ABSTRACT_FROM' => 'lib_pm.PL',
  'AUTHOR' => 'Steffen Mueller <smueller@cpan.org>',
  'INSTALLDIRS' => 'perl',
  'clean' => {FILES => 'lib.pm'},
);

