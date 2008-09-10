use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Sub::Assert',
    'VERSION_FROM'	=> 'lib/Sub/Assert.pm', # finds $VERSION
    'LICENSE' => 'perl',
    'PREREQ_PM'		=> {Carp => 0, Exporter => 0, Test::More=>0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Sub/Assert.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
