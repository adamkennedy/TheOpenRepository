#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Path ();
use File::Spec::Functions ':ALL';
use_ok( 't::lib::Test' );

# Create the dist object
my $dist = t::lib::Test->new2;
isa_ok( $dist, 't::lib::Test2' );

# Run the dist object, and ensure everything we expect was created
diag( "Building test dist, may take up to an hour... (sorry)" );
ok( $dist->run, '->run ok' );
