# No Scalar::Util weaken before 5.008
require 5.008;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Weaken',
    AUTHOR              => 'Jeffrey Kegler <nospam@no.spam>',
    VERSION_FROM        => 'lib/Test/Weaken.pm',
    ABSTRACT_FROM       => 'lib/Test/Weaken.pm',
    NO_META             => 1,
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Scalar::Util' => '1.18',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Weaken-*' },
);
