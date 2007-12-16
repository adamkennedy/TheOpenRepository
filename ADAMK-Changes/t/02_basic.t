#!/usr/bin/perl

# Test using our own changes file

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use ADAMK::Changes;





#####################################################################
# Test the Config::Tiny Changes file

SCOPE: {
	my $file = catfile('t', 'data', 'Config-Tiny');
	ok( -f $file, 'Found Config-Tiny Changes file' );
	my $changes = ADAMK::Changes->read($file);
	isa_ok( $changes, 'ADAMK::Changes');
	is( $changes->dist_name,   'Config-Tiny',  '->dist_name ok'   );
	is( $changes->module_name, 'Config::Tiny', '->module_name ok' );
	is( scalar($changes->releases), 26, '->releases is 26' );
	isa_ok( $changes->current_release, 'ADAMK::Changes::Release' );
	is( $changes->current_version, '2.12', '->current_version ok' );
}
