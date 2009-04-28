#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT}) {
		plan( tests => 6 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use ADAMK::Repository;

my $repository = ADAMK::Repository->new(
	path    => $ENV{ADAMK_CHECKOUT},
	preload => 1,
);
isa_ok( $repository, 'ADAMK::Repository' );





#####################################################################
# Get the CPAN Testers results

my $distribution = $repository->distribution('Config-Tiny');
isa_ok( $distribution, 'ADAMK::Distribution' );
my $release = $distribution->stable;
isa_ok( $release, 'ADAMK::Release' );
my $testers = $release->cpan_testers;
is( ref($testers), 'HASH', 'Got CPAN Testers results' );
ok( $testers->{PASS}, 'Found CPAN Testers PASS results' );
is( $testers->{FAIL}, undef, 'No CPAN Testers failures' );
