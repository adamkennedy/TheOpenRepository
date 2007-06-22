#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use File::Remove 'remove';
use Games::EVE::Killmail::Store;

my $testdb = catfile( 'data', 'testdb.sqlite' );
remove( $testdb ) if -e $testdb;
ok( ! -f $testdb, 'Test DB does not exist' );
ok(
	Games::EVE::Killmail::Store->import( $testdb ),
	'->import( testdb ) ok',
);
