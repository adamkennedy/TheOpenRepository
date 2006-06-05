
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'PITA::Guest::Driver::VMware',
    AUTHOR          => 'Uwe Voelker <uwe.voelker@gmx.de>',
    VERSION_FROM    => 'lib/PITA/Guest/Driver/VMware.pm',
    ABSTRACT_FROM   => 'lib/PITA/Guest/Driver/VMware.pm',
    PL_FILES        => {},
    PREREQ_PM    => {
        'Test::More'    => 0,
        'version'       => 0,
    },
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean           => { FILES => 'lib/PITA/Guest/Driver/VMware.pm-*' },
);
