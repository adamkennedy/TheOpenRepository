use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::Telstra::PhoneBill',
    VERSION_FROM      => 'lib/Business/Telstra/PhoneBill.pm', # finds $VERSION
    PREREQ_PM         => {
                              Archive::Zip => 1.13,
                              Text::CSV_XS => 0.23,
                              File::Type   => 0.20,
                              Tie::File    => 0.97,
                              
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/Telstra/PhoneBill.pm', # retrieve abstract from module
       AUTHOR         => 'Renee Baecker <module@renee-baecker.de>') : ()),
);
