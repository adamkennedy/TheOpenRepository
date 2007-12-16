#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use ADAMK::Changes;





#####################################################################
# Parse our own Changes file

ok( -f 'Changes', 'Found Changes file' );
my $changes = ADAMK::Changes->read('Changes');
isa_ok( $changes, 'ADAMK::Changes' );
is( $changes->dist_name,   'ADAMK-Changes',  '->dist_name ok'   );
is( $changes->module_name, 'ADAMK::Changes', '->module_name ok' );
