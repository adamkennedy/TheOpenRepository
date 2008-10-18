use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'Filter::Simple',
  VERSION_FROM  => 'lib/Filter/Simple.pm',
  ABSTRACT_FROM => 'lib/Filter/Simple.pm',
  INSTALLDIRS   => 'perl',
  'LICENSE'     => 'perl',
  'AUTHOR'      => 'Damian Conway',
  'INSTALLDIRS' => 'perl',
  PREREQ_PM     => {
    'Text::Balanced' => 0,
    'Filter::Util::Call' => 0
  },
);
