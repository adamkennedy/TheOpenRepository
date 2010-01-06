#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Aspect;

# Do a lexical and make sure it produces lexical advice
SCOPE: {
	my $aspect = aspect Wormhole => 'One::a', 'Three::a';
	my $object = One->new;
	is( $object->a, $object, 'One::a returns instance of calling object' );
}

# Repeat using a global aspect and make sure it produces global advice
aspect Wormhole => 'One::b', 'Three::b';
my $object = One->new;
is( $object->b, $object, 'One::b returns instance of calling object' );

package One;

sub new {
	bless {}, shift;
}

sub a {
	Two->a;
}

sub b {
	Two->b;
}

package Two;

sub a {
	Three->a;
}

sub b {
	Three->b;
}

package Three;

sub a {
	pop;
}

sub b {
	pop;
}
