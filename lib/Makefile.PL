## This -*- perl -*- script writes the Makefile for lib.pm
# You should read "perldoc perlmodinstall" for instructions on
#  how to install modules like this.

require 5.006_001;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME' => 'lib',
  'VERSION' => '0.58',
  'LICENSE' => 'perl',
  'PREREQ_PM' => {},
  'ABSTRACT_FROM' => 'lib_pm.PL',
  'AUTHOR' => 'Steffen Mueller <smueller@cpan.org>',
  'INSTALLDIRS' => 'perl',
  'PL_FILES' => {'lib_pm.PL' => 'lib.pm'},
  'PM' => {'lib.pm' => '$(INST_LIBDIR)/lib.pm'},
  'clean' => {FILES => 'lib.pm'},
  ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
    (EXTRA_META => <<EMETA,
provides:
  lib:
    file: lib_pm.PL
    version: 0.58
EMETA
    ) : ()),
);


