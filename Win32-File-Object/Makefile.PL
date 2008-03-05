use strict;
use ExtUtils::MakeMaker;

# This module is only for Win32
unless ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
	print "Win32::File::Object is only applicable to Win32 and cygwin\n";
	print "Install Result: N/A\n";
	exit(255);
}

WriteMakefile(
	'NAME'         => 'Win32::File::Object',
	'VERSION_FROM' => 'lib/Win32/File/Object.pm', # finds $VERSION
	'NO_META'      => 1,
	'PREREQ_PM'    => {
		'Win32::File'  => '0.05',
		'File::Spec'   => '0.80',
		'File::Remove' => '0.38',
		'Test::More'   => '0.42',
	},
);
