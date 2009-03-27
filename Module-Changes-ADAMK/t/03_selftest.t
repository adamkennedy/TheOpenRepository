#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Module::Changes::ADAMK;





#####################################################################
# Parse our own Changes file

ok( -f 'Changes', 'Found Changes file' );
my $changes = Module::Changes::ADAMK->read('Changes');
isa_ok( $changes, 'Module::Changes::ADAMK' );
is( $changes->dist_name,   'Module-Changes-ADAMK',  '->dist_name ok'   );
is( $changes->module_name, 'Module::Changes::ADAMK', '->module_name ok' );
my $current = $changes->current_release;
isa_ok( $current, 'Module::Changes::ADAMK::Release' );
is( $current->version, '0.01', '->version ok' );
is( $current->date, 'Sun 16 Dec 2007', '->date ok' );
my @changes = $current->changes;
is( scalar(@changes), 2, 'Found 2 changes' );
my $change = $changes[0];
isa_ok( $change, 'Module::Changes::ADAMK::Change' );
is( $change->author, 'ADAMK', '->author ok' );
is( $change->message, 'Created the initial version', '->message ok' );
