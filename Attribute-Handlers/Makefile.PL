use 5.006;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'Attribute::Handlers',
  VERSION_FROM  => 'lib/Attribute/Handlers.pm',
  INSTALLDIRS   => 'perl',
  'LICENSE'     => 'perl',
  'INSTALLDIRS' => 'perl',
  ($] >= 5.005 ?
  (ABSTRACT_FROM => 'lib/Attribute/Handlers.pm',
   'AUTHOR'      => 'Damian Conway') : ()),
);
