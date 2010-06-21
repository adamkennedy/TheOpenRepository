#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
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

# Find a particular named dialog
my $dialog1 = $object->dialog('MyDialog1');
isa_ok( $dialog1, 'FBP::Dialog' );
is( $dialog1->name, 'MyDialog1', '->name ok' );

# Repeat using the generic search
my $dialog2 = $object->find_first(
	isa  => 'FBP::Dialog',
	name => 'MyDialog1',
);
isa_ok( $dialog2, 'FBP::Dialog' );
is(
	$object->find_first( name => 'does_not_exists' ),
	undef,
	'->find_first(bad) returns undef',
);
