#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Win32::Capture::Raw;

my $rv = Win32::Capture::Raw::capture();

1;
