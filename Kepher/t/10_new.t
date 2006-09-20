#!/usr/bin/perl -w

# Construct a Kepher object, but don't start it

use strict;
BEGIN {
	$| = 1;
}

use Test::More tests => 1;
use Kepher;

# Create the new Kepher object
my $kepher = Kepher->new;
isa_ok( $kepher, 'Kepher' );

exit(0);
