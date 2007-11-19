#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;

my @PACKAGES = qw{
	binutils-2.17.50-20060824-1.tar.gz
	dmake-4.8-20070327-SHAY.zip
	gcc-core-3.4.5-20060117-1.tar.gz
	gcc-g++-3.4.5-20060117-1.tar.gz
	gmp-4.2.1-vanilla.zip
	libxml2-2.6.30.win32.zip
	mingw-runtime-3.13.tar.gz
	mingw32-make-3.81-2.tar.gz
	pexports-0.43-1.zip
	w32api-3.10.tar.gz
	zlib-1.2.3.win32.zip
};

plan( tests => scalar(@PACKAGES) );

use Perl::Dist::Downloads ();
use File::ShareDir ':ALL';

foreach ( @PACKAGES ) {
	ok( -f dist_file('Perl-Dist-Downloads', $_), "Found $_" );
}
