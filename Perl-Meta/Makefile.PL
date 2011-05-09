use 5.005;
use strict;
#use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl::Meta',
    AUTHOR              => q{Alexandr Ciornii <alexchorny@gmail.com>},
    VERSION_FROM        => 'lib/Perl/Meta.pm',
    ABSTRACT_FROM       => 'lib/Perl/Meta.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl-Meta-*' },
);
