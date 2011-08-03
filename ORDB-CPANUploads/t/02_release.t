#!/usr/bin/perl

# Don't download stuff just to install the module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Params::Util ();
use LWP::Online ':skip_all';
unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
	exit(0);
}

plan tests => 2;

use_ok('ORDB::CPANUploads');

# Find the age of the sqlite file by using the most recent upload
my $age = ORDB::CPANUploads->age;
ok( Params::Util::_POSINT($age), 'Got positive integer seconds for ->age' );
