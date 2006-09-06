#!/usr/bin/perl -w

# Compile testing for asa

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;





#####################################################################
# Define a class that uses POE::Thing

package Foo;

use base 'POE::Thing';

use myevent :Event {
	print "Hello World!\n";
}

exit(0);
