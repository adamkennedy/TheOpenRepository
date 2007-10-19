#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'Imager::Search'                    );
use_ok( 'Imager::Search::Pattern'           );
use_ok( 'Imager::Search::Image::File'       );
use_ok( 'Imager::Search::Image::Cached'     );
use_ok( 'Imager::Search::Image::Screenshot' );
use_ok( 'Imager::Search::Driver::HTML8'     );
