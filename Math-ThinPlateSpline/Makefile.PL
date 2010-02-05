use 5.008;
use ExtUtils::MakeMaker;
use File::Spec;

my $CC = 'g++';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::ThinPlateSpline',
    VERSION_FROM      => 'lib/Math/ThinPlateSpline.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::XSpp' => '0.08',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/ThinPlateSpline.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-O2', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Itpsfit/src', # e.g., '-I. -I/usr/include/other'
     OBJECT            => '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++ -hiertype',
    'TYPEMAPS'          => ['perlobject.map'],
    'CC'                => $CC,
    'LD'                => '$(CC)',
    META_MERGE => { no_index => { directory => 'buildtools', }, },
    #clean => {
    #  FILES => "",
    #},
);


