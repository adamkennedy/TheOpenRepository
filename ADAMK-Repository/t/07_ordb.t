#!/usr/bin/perl

# Test integration with the ORDB:: modules

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT}) {
		plan( tests => 10 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use ADAMK::Repository;

my $repository = ADAMK::Repository->new(
	path => $ENV{ADAMK_CHECKOUT},
);
isa_ok( $repository, 'ADAMK::Repository' );





#####################################################################
# ORDB::CPANUploads Integration

# Test a module we know will never be uploaded
SCOPE: {
	my $distribution = $repository->distribution('ADAMK-Repository');
	isa_ok( $distribution, 'ADAMK::Distribution' );
	my $release = $distribution->latest;
	isa_ok( $release, 'ADAMK::Release' );
	my @upload = $release->upload;
	is( scalar(@upload), 0, 'No uploads for ADAMK-Repository' );
}

# Test a distribution that has been uploaded
SCOPE: {
	my $distribution = $repository->distribution('Config-Tiny');
	isa_ok( $distribution, 'ADAMK::Distribution' );
	my @uploads = $distribution->uploads;
	ok( scalar(@uploads) > 10, '->uploads ok' );
	isa_ok( $uploads[0], 'ORDB::CPANUploads::Uploads' );
	my $release = $distribution->latest;
	isa_ok( $release, 'ADAMK::Release' );
	my @upload = $release->upload;
	is( scalar(@upload), 1, 'One upload for a Config::Tiny release' );
	isa_ok( $upload[0], 'ORDB::CPANUploads::Uploads' );
}
