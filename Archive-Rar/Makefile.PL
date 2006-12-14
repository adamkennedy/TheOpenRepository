#!perl

my $iswindows = 0;
$iswindows = 1 if $^O =~ /win32/i;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
    (
     'NAME' => 'Archive::Rar',
     'VERSION_FROM' => 'lib/Archive/Rar.pm', # finds $VERSION
     'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
     'PREREQ_PM' => {
         'Data::Dumper' => '0',
         'Test::Simple' => '0',
         ($iswindows ? ('Win32::Registry' => '0') : () ),
     },
     'LICENSE' => 'perl',
     $] >= 5.005 ? ('AUTHOR' => 'jean-marc boulade <jmbperl@hotmail.com>',
		    'ABSTRACT' => 'Manipulates RAR archives') : ()
    );
