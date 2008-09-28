## This -*- perl -*- script writes the Makefile for lib.pm
# You should read "perldoc perlmodinstall" for instructions on
#  how to install modules like this.

require 5.006_001;
use strict;
use ExtUtils::MakeMaker;

my $extra_meta = <<'EMETA';
provides:
  lib:
    file: lib_pm.PL
    version: 0.59_01
EMETA
my $mm_version = $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
  'NAME' => 'lib',
  'VERSION' => '0.59_01',
  'LICENSE' => 'perl',
  'PREREQ_PM' => {},
  'ABSTRACT_FROM' => 'lib_pm.PL',
  'AUTHOR' => 'Steffen Mueller <smueller@cpan.org>',
  'INSTALLDIRS' => 'perl',
  'PL_FILES' => {'lib_pm.PL' => 'lib.pm'},
  'PM' => {'lib.pm' => '$(INST_LIBDIR)/lib.pm'},
  'clean' => {FILES => 'lib.pm'},
  (
    $mm_version >= 6.46
    ? (META_ADD => $extra_meta)
    : ( 
        $mm_version >= 6.3002
        ? (EXTRA_META => $extra_meta)
        : ()
      )
  ),
);


