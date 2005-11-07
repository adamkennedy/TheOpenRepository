use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::Telstra::PhoneBill::Download',
    VERSION_FROM      => 'lib/Business/Telstra/PhoneBill/Download.pm', # finds $VERSION
    PREREQ_PM         => {
                            WWW::Mechanize               => 1.16,
                            HTTP::Cookies                => 1.39,
                            Business::Telstra::PhoneBill => 0.01,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/Telstra/PhoneBill/Download.pm', # retrieve abstract from module
       AUTHOR         => 'Renee Baecker <module@renee-baecker.de>') : ()),
);
