use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl::APIReference',
    VERSION_FROM      => 'lib/Perl/APIReference.pm', # finds $VERSION
    PREREQ_PM         => {
      'parent' => '0',
      'Data::Dumper' => '0',
      'Class::XSAccessor' => '1.03',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Perl/APIReference.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
