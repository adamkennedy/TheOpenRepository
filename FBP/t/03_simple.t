#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use FBP ();

my $FILE = catfile( 't', 'data', 'simple.fbp' );
ok( -f $FILE, "Found test file '$FILE'" );





######################################################################
# Simple Tests

# Create the empty object
my $object = FBP->new;
isa_ok( $object, 'FBP' );

# Parse the file
my $ok = eval {
	$object->parse_file( $FILE );
};
is( $@, '', "Parsed '$FILE' without error" );
ok( $ok, '->parse_file returned true' );
