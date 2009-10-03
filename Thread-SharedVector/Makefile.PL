use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $CC = 'g++';

WriteMakefile(
    NAME              => 'Thread::SharedVector',
    VERSION_FROM      => 'lib/Thread/SharedVector.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::XSpp' => '0.04',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Thread/SharedVector.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-O2', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Isrc', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
     OBJECT            => '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++ -hiertype',
    'TYPEMAPS'          => ['perlobject.map'],
    'CC'                => $CC,
    'LD'                => '$(CC)',
);

