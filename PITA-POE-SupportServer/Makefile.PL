use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'                     => 'PITA::POE::SupportServer',
    'VERSION_FROM'             => 'lib/PITA/POE/SupportServer.pm', # finds $VERSION
    'PREREQ_PM' => {
        'POE'                  => undef,
        'Carp'                 => undef,
        'PITA-Test-Image-Qemu' => '0.02'
    },
    'dist' => {
        'SUFFIX'               => ".gz",
        'DIST_DEFAULT'         => 'all tardist',
        'COMPRESS'             => "gzip -9vf",
    },
);
