#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 18;
use File::Spec::Functions ':ALL';
use Imager;
use Imager::Search::RRGGBB;





#####################################################################
# Load the Test Files

# Testing is done with bmp files, since that doesn't need external libs
my $big_file   = catfile( 't', 'data', '02_simple', 'big.bmp' );
my $small_file = catfile( 't', 'data', '02_simple', 'small.bmp' );
ok( -f $big_file,   'Found big file'   );
ok( -f $small_file, 'Found small file' );

my $big = Imager->new;
isa_ok( $big, 'Imager' );
ok( $big->read( file => $big_file ), '->open ok' );
is( $big->getchannels, 3, '->channels is 3' );
is( $big->bits, 8, '->bits is 8' );

my $small = Imager->new;
isa_ok( $small, 'Imager' );
 ok( $small->read( file => $small_file ), '->open ok' );
is( $small->getchannels, 3, '->channels is 3' );
is( $small->bits, 8, '->bits is 8' );






#####################################################################
# Test Construction

my $search = Imager::Search::RRGGBB->new(
	big   => $big,
	small => $small,
);
isa_ok( $search, 'Imager::Search::RRGGBB' );
isa_ok( $search->big,   'Imager' );
isa_ok( $search->small, 'Imager' );

# Get the small_string
my $small_string = $search->small_string;
is( ref($small_string), 'SCALAR', '->small_string returns a SCALAR' );
is( length($$small_string), 644, '->small_string correct length' );

# Do a simple search
my $position = $search->find_first;
is( ref($position), 'HASH', '->find_first returns a HASH as expected' );
is( $position->{x}, 26,  '->{x} is 26'  );
is( $position->{y}, 135, '->{y} is 135' );
foreach ( 0 .. 10 ) {
	$search->find_first;
}
