use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::WiX3::Objects',
    AUTHOR              => 'Curtis Jewell <csjewell@cpan.org>',
    VERSION_FROM        => 'lib/XML/WiX3/Objects.pm',
    ABSTRACT_FROM       => 'lib/XML/WiX3/Objects.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-WiX3-Objects-*' },
);
