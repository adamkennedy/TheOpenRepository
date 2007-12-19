#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use Perl::Dist::Util::Toolchain ();

@Perl::Dist::Util::Toolchain::DELEGATE = (
	'perl',
	'-I' . File::Spec->catdir('blib', 'lib'),
);





#####################################################################
# Create and execute a resolver

SCOPE: {
	my $toolchain = Perl::Dist::Util::Toolchain->new('File::Spec');
	isa_ok(
		$toolchain,
		'Perl::Dist::Util::Toolchain'
	);
	ok( $toolchain->prepare, '->prepare ok' );
	ok( $toolchain->run, '->run ok' );
	ok( $toolchain->{dists}->[0] =~ /PathTools/, 'Found expected filename' );
}

SCOPE: {
	my $toolchain = Perl::Dist::Util::Toolchain->new('File::Spec');
	isa_ok(
		$toolchain,
		'Perl::Dist::Util::Toolchain'
	);
	ok( $toolchain->delegate, '->prepare ok' );
	ok( $toolchain->{dists}->[0] =~ /PathTools/, 'Found expected filename' );
}

1;
