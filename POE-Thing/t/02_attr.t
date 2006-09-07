#!/usr/bin/perl -w

# Compile testing for asa

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;





#####################################################################
# Attribute tests

my $state_hash = POE::Thing::Registry::inline_states('Foo');
is( ref($state_hash), 'HASH', 'inline_states returns a HASH' );
my @states = %{ $state_hash };
is( scalar(@states), 2, 'Got one state' );
is( $states[0], 'myevent', 'Got state for "myevent"' );
is( ref($states[1]), 'CODE', 'State points to a CODE ref' );





#####################################################################
# Define a class that uses POE::Thing

package Foo;

use base 'POE::Thing';

sub myevent :Event {
	print "Hello World!\n";
}

exit(0);
