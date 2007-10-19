#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use Imager::Search::Image::File;

my $file1 = catfile( 't', 'data', 'basic', 'big.bmp');
ok( -f $file1, 'Test file 1 exists' );





#####################################################################
# Trivial Test Files

my $image1 = Imager::Search::Image::File->new(
	driver => 'HTML8',
	file   => $file1,
);
isa_ok( $image1, 'Imager::Search::Image::File' );
