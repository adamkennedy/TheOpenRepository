#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

# Is the perl version new enough
ok( $] >= 5.005, 'Perl version is new enough' );

# Load the module
use_ok( 'CGI::Install' );
