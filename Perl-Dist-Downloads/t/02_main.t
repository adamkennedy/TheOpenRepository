#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;

use Perl::Dist::Downloads ();
use File::ShareDir ':ALL';

foreach ( qw{
	binutils-2.17.50-20060824-1.tar.gz
	dmake-4.8-20070327-SHAY.zip
	gcc-core-3.4.5-20060117-1.tar.gz
	gcc-g++-3.4.5-20060117-1.tar.gz
	mingw32-make-3.81-2.tar.gz
	perl-5.8.8.tar.gz
	w32api-3.10.tar.gz
} ) {
	ok( -f dist_file('Perl-Dist-Downloads', $_), "Found $_" );
}

