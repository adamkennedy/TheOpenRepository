use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Env::Constant',
    VERSION_FROM      => 'lib/Env/Constant.pm', # finds $VERSION
    PREREQ_PM         => {
      constant => 1.01,
    },
    ABSTRACT_FROM  => 'lib/Env/Constant.pm', # retrieve abstract from module
    AUTHOR         => 'Steffen Mueller <smueller@cpan.org>'
);
