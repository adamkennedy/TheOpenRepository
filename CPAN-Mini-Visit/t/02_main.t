#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use CPAN::Mini::Visit ();

my $visit = new_ok( 'CPAN::Mini::Visit' => [
	root     => 'D:\minicpan',
	acme     => 0,
	author   => 'ADAMK',
	callback => sub {
		print STDERR $_[0] . "\n";
	},
] );

ok( $visit->run, '->run ok' );
