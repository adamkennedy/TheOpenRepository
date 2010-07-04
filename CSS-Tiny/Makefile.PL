use strict;
use vars qw{$VERSION};
BEGIN {
	require 5.004;
	$VERSION = '1.17';
}
use ExtUtils::MakeMaker;

WriteMakefile(
	MIN_PERL_VERSION => '5.004',
	META_MERGE => {
		resources => {
			repository => 'http://svn.ali.as/cpan/trunk/CSS-Tiny',
		},
	},
	NAME      => 'CSS::Tiny',
	ABSTRACT  => 'Read/Write .css files with as little code as possible',
	VERSION   => $VERSION,
	PREREQ_PM => {
	},
	BUILD_REQUIRES => {
		# Skip on Windows to avoid breaking ActivePerl PPMs
		# 0.47 means 5.6.2 or newer, which everyone on Win32 has.
		($^O eq 'MSWin32' ? () : ('Test::More' => '0.47')),
	},
	AUTHOR  => 'Adam Kennedy <adamk@cpan.org>',
	LICENSE => 'perl',
	(-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
		test => {
			TESTS => 't/*.t xt/*.t',
		},
	) : (),
);

sub WriteMakefile {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
	my %params=@_;
	my $eumm_version=$ExtUtils::MakeMaker::VERSION;
	$eumm_version=eval $eumm_version;
	if ( $params{BUILD_REQUIRES} and $eumm_version < 6.5503 ) {
		#EUMM 6.5502 has problems with BUILD_REQUIRES
		$params{PREREQ_PM} = {
			%{$params{PREREQ_PM} || {}},
			%{$params{BUILD_REQUIRES}}
		};
		delete $params{BUILD_REQUIRES};
	}
	delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
	delete $params{META_MERGE} if $eumm_version < 6.46;
	delete $params{LICENSE} if $eumm_version < 6.31;
	delete $params{AUTHOR} if $] < 5.005;

	ExtUtils::MakeMaker::WriteMakefile(%params);
}
