use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Physics::Lorentz',
    VERSION_FROM      => 'lib/Physics/Lorentz.pm', # finds $VERSION
    PREREQ_PM         => {
      Params::Util => '0',
      PDL => '0',
      Test::LectroTest => '0.3500',
    }, # e.g., Module::Name => 1.1
    LICENSE => 'perl',
    ABSTRACT_FROM  => 'lib/Physics/Lorentz.pm', # retrieve abstract from module
    AUTHOR         => 'Steffen Müller <tsee@>',
);
