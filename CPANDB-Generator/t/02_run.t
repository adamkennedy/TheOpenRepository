#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use CPANDB::Generator ();

my $cpandb = new_ok( 'CPANDB::Generator' => [] );
ok( $cpandb->run, '->run' );
