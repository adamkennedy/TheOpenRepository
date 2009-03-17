use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME              => 'Math::Random::ISAAC',
  VERSION_FROM      => 'ISAAC.pm', # finds $VERSION
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'ISAAC.pm', # retrieve abstract from module
     AUTHOR         => 'Jonathan Yu <frequency@cpan.org>') : ()),
  LIBS              => [''], # e.g., '-lm'
  DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
  INC               => '-I.', # e.g., '-I.'

  # Un-comment this if you add C files to link with later:
  OBJECT            => '$(O_FILES)', # link all the C files too
);
