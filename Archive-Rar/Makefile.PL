#! - perl -
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
    (
     'NAME' => 'Archive::Rar',
     'VERSION_FROM' => 'Rar.pm', # finds $VERSION
     'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
     $] >= 5.005 ? ('AUTHOR' => 'jean-marc boulade <jmbperl@hotmail.com>',
		    'ABSTRACT' => 'Manipulates RAR archives') : ()
    );
