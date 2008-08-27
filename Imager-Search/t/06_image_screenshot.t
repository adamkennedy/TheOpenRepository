#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use Imager::Search::Image::Screenshot;





#####################################################################
# Trivial Test Files

my $image1 = Imager::Search::Image::Screenshot->new( driver => 'HTML8' );
isa_ok( $image1, 'Imager::Search::Image::Screenshot' );

# Confirm the string is the expected size
my $str_ref  = $image1->string;
my $expected = $image1->width * $image1->height * 7;
is( length($$str_ref), $expected, '->string is the expected length' );
