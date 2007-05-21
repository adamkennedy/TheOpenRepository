#!/use/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More test => 2;
use File::Spec::Functions ':ALL';
use SQLite::Default;

my $file1 = catfile( 't', 'data', 'file1.sqlite' );

