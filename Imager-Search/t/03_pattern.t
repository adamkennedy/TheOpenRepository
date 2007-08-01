#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use Imager;
use Imager::Search;





#####################################################################
# Load the Test Files

# Testing is done with bmp files, since that doesn't need external libs
my $small_file = catfile( 't', 'data', 'basic', 'small.bmp' );
ok( -f $small_file, 'Found small file' );

my $small = Imager->new;
isa_ok( $small, 'Imager' );
ok( $small->read( file => $small_file ), '->open ok' );
is( $small->getchannels, 3, '->channels is 3' );
is( $small->bits, 8, '->bits is 8' );






#####################################################################
# Test Pattern Construction

my $pattern = Imager::Search::Pattern->new(
	driver => 'Imager::Search::Driver::HTML8',
	image  => $small,
);
isa_ok( $pattern, 'Imager::Search::Pattern' );
isa_ok( $pattern->driver, 'Imager::Search::Driver' );
isa_ok( $pattern->driver, 'Imager::Search::Driver::HTML8' );
isa_ok( $pattern->image, 'Imager' );
