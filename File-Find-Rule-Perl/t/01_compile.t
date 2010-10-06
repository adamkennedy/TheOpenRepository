#!/usr/bin/perl

# Load testing for File::Find::Rule::Perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

use_ok( 'File::Find::Rule::Perl' );

ok( defined &find, 'Exported the expected symbol' );
