#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use Imager::Search                ();
use Imager::Search::Pattern       ();
use Imager::Search::Image::File   ();
use Imager::Search::Driver::HTML24 ();

my $small = catfile( 't', 'data', 'basic', 'small2.bmp' );
ok( -f $small, 'Found small file' );

my $big = catfile( 't', 'data', 'basic', 'big2.bmp' );
ok( -f $big, 'Found big file' );





#####################################################################
# Execute the search

my $pattern = Imager::Search::Pattern->new(
	driver => 'Imager::Search::Driver::HTML24',
	file   => $small,
);
isa_ok( $pattern, 'Imager::Search::Pattern' );

my $target = Imager::Search::Image::File->new(
	driver => 'Imager::Search::Driver::HTML24',
	file   => $big,
);
isa_ok( $target, 'Imager::Search::Image::File' );

my @matches = $target->find( $pattern );
my $first   = $target->find_first( $pattern );
my $boolean = $target->find_any( $pattern );





#####################################################################
# Check the results

is( scalar(@matches), 2, 'Found 2 matches' );
is_deeply( $first, $matches[0], 'find_first ok' );
is( $boolean, 1, 'find_any ok' );
