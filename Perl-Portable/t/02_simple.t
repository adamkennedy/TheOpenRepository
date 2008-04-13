#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'Perl::Portable' );
