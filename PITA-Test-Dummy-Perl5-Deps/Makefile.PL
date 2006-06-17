use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'PITA::Test::Dummy::Perl5::Deps',
    AUTHOR        => 'Adam Kennedy <cpan@ali.as>',
    VERSION       => '1.00',
    ABSTRACT      => 'Darren, the CPAN Test Dummy for Perl modules with dependencies',
    PL_FILES      => {},
    PREREQ_PM     => {
        'PITA::Test::Dummy::Perl5::Make'  => '1.01',
        'PITA::Test::Dummy::Perl5::Build' => '1.00',
        'PITA::Test::Dummy::Perl5::MI'    => '0.63',
    },
);
