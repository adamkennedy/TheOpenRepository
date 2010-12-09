#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 2;
use ADAMK::SDL::Test;

my $app = ADAMK::SDL::Test->new;
isa_ok( $app, 'ADAMK::SDL::Test' );
ok( $app->update, '->update ok' );
is( $app->run, 0, '->run ok' );
print "Exiting\n";
exit(0);
