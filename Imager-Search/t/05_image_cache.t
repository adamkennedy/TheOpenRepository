#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use Imager::Search::Image::Cached;

my $file1 = catfile( 't', 'data', 'cached', 'trivial.txt');
ok( -f $file1, 'Test file 1 exists' );





#####################################################################
# Trivial Test Files

my $image1 = Imager::Search::Image::Cached->read( $file1 );
isa_ok( $image1, 'Imager::Search::Image::Cached' );
