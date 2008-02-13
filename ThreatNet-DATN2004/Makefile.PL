use strict;
use vars qw{$VERSION};
BEGIN {
	require 5.003_96;
	$VERSION = '0.02';
}
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'ThreatNet::DATN2004',
	ABSTRACT  => 'Proposal: The Decentralised Active Threat Network',
	VERSION   => $VERSION,
	PREREQ_PM => {},
	($] >= 5.005 ? (
		AUTHOR  => 'Adam Kennedy <adamk@cpan.org>',
	) : ()),
	($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : ()),
);
