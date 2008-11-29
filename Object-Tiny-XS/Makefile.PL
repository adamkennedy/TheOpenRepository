use strict;
use 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Object::Tiny::XS',
        VERSION_FROM      => 'lib/Object/Tiny/XS.pm', # finds $VERSION
	PREREQ_PM => {
                'Class::XSAccessor' => '0.11',
		# Skip on Windows to avoid breaking ActivePerl PPMs
		# 0.47 means 5.6.2 or newer, which everyone on Win32 has.
		($^O eq 'MSWin32' ? () : ('Test::More' => '0.47')),
	},
	($] >= 5.005 ? (
		AUTHOR  => 'Steffen Mueller <smueller@cpan.org>',
		ABSTRACT_FROM  => 'lib/Object/Tiny/XS.pm',
	) : ()),
	($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : ()),
);
