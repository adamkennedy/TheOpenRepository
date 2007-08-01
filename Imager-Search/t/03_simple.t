#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 36;
use File::Spec::Functions ':ALL';
use Imager;
use Imager::Search;





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

my $pattern = Imager::Search::Pattern->new(
	
);
isa_ok( $search, 'Imager::Search::RRGGBB' );
isa_ok( $search->big,   'Imager' );
isa_ok( $search->small, 'Imager' );

# Get the small_string
my $small_string = $search->_small_string;
is( ref($small_string), 'SCALAR', '->_small_string returns a SCALAR' );
is( length($$small_string), 644, '->_small_string correct length' );

# Do a simple search
my $position = $search->find_first;
isa_ok( $position, 'Imager::Search::Match' );
is( $position->left,     6,  '->left ok'      );
is( $position->right,    18, '->right ok'     );
is( $position->top,      74, '->top ok'       );
is( $position->bottom,   86, '->bottom ok'    );
is( $position->width,    13, '->width ok'     );
is( $position->height,   13, '->height ok'    );
is( $position->center_x, 12, '->center_x ok ' );
is( $position->center_y, 80, '->center_y ok'  );

# Find all of them
my @all = $search->find;
is(scalar(@all), 3, 'Found 3 matches' );
isa_ok( $all[0], 'Imager::Search::Match' );
is( $all[0]->left,     6,  '->left ok'      );
is( $all[0]->right,    18, '->right ok'     );
is( $all[0]->top,      74, '->top ok'       );
is( $all[0]->bottom,   86, '->bottom ok'    );
is( $all[0]->width,    13, '->width ok'     );
is( $all[0]->height,   13, '->height ok'    );
is( $all[0]->center_x, 12, '->center_x ok ' );
is( $all[0]->center_y, 80, '->center_y ok'  );
isa_ok( $all[1], 'Imager::Search::Match' );
isa_ok( $all[2], 'Imager::Search::Match' );
