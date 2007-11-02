use strict;
use vars qw{$VERSION};
BEGIN {
	require 5.003_96;
	$VERSION = '1.15';
}
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'CSS::Tiny',
	ABSTRACT  => 'Read/Write .css files with as little code as possible',
	VERSION   => $VERSION,
	PREREQ_PM => {
		'Test::More' => '0.47',
	},
	($] >= 5.005 ? (
		AUTHOR  => 'Adam Kennedy <adamk@cpan.org>',
	) : ()),
	($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : ()),
);
