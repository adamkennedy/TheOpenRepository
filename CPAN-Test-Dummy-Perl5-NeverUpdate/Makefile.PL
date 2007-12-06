use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'CPAN::Test::Dummy::Perl5::NeverUpdate',
    AUTHOR        => 'Adam Kennedy <adamk@cpan.org>',
    VERSION       => '1.00',
    ABSTRACT      => 'CPAN Test Dummy that will never have an updated release',
    PL_FILES      => {},
);
