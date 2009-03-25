#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use ADAMK::Changes;





#####################################################################
# Parse our own Changes file

ok( -f 'Changes', 'Found Changes file' );
my $changes = ADAMK::Changes->read('Changes');
isa_ok( $changes, 'ADAMK::Changes' );
is( $changes->dist_name,   'ADAMK-Changes',  '->dist_name ok'   );
is( $changes->module_name, 'ADAMK::Changes', '->module_name ok' );
my $current = $changes->current_release;
isa_ok( $current, 'ADAMK::Changes::Release' );
is( $current->version, '0.01', '->version ok' );
is( $current->date, 'Sun 16 Dec 2007', '->date ok' );
my @changes = $current->changes;
is( scalar(@changes), 2, 'Found 2 changes' );
my $change = $changes[0];
isa_ok( $change, 'ADAMK::Changes::Change' );
is( $change->author, 'ADAMK', '->author ok' );
is( $change->message, 'Created the initial version', '->message ok' );
