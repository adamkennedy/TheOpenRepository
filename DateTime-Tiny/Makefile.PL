use strict;
use vars qw{$VERSION};
BEGIN {
	require 5.004;
	$VERSION = '1.04';
}
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'DateTime::Tiny',
	ABSTRACT  => 'A datetime object with as little code as possible',
	VERSION   => $VERSION,
	PREREQ_PM => {
		# Skip on Windows to avoid breaking ActivePerl PPMs
		# 0.47 means 5.6.2 or newer, which everyone on Win32 has.
		($^O eq 'MSWin32' ? () : ('Test::More' => '0.47')),
	},
	($] >= 5.005 ? (
		AUTHOR  => 'Adam Kennedy <adamk@cpan.org>',
	) : ()),
	($ExtUtils::MakeMaker::VERSION ge '6.31' ? (
		LICENSE => 'perl',
	) : ()),
	($ExtUtils::MakeMaker::VERSION ge '6.48' ? (
		MIN_PERL_VERSION => 5.004,
		META_MERGE => {
			resources => {
				repository => 'http://svn.ali.as/cpan/trunk/DateTime-Tiny',
			},
		},
	) : ()),
);
