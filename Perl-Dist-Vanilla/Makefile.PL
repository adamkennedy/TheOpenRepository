use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Perl::Dist::Vanilla',
    VERSION_FROM      => 'lib/Perl/Dist/Vanilla.pm', # finds $VERSION
    PREREQ_PM         => {
        'Archive::Tar'      => 1.29, 
        'Archive::Zip'      => 1.16,
        'File::Path'        => 1.08, 
        'File::pushd'       => 0.32,
        'File::Spec'        => 3.17,
        'HTTP::Status'      => 1.28,
        'LWP::UserAgent'    => 2.033,
        'Perl6::Say'        => 0.04,
        'Sub::Exporter'     => 0.966,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ( ABSTRACT_FROM   => 'lib/Perl/Dist/Vanilla.pm', # retrieve abstract from module
        AUTHOR          => 'David A Golden <dagolden@cpan.org>',
        NO_META         => 1 # doing this by hand
      ) : ()),
);
