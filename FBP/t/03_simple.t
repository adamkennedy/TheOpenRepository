#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 22;
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

# Check the project properties
my $project = $object->find_first( isa => 'FBP::Project' );
isa_ok( $project, 'FBP::Project' );
is( $project->internationalize, '1', '->internationalize ok' );

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

# The search should work as well from children of the main object as well

my $dialog3 = $project->find_first( isa => 'FBP::Dialog' );
isa_ok( $dialog3, 'FBP::Dialog' );

# Text properties
my $text = $object->find_first(
	isa => 'FBP::StaticText',
);
isa_ok( $text, 'FBP::StaticText' );
is( $text->id,      'wxID_ANY',       '->id ok'      );
is( $text->name,    'm_staticText1',  '->name ok'    );
is( $text->label,   'This is a test', '->label ok'   );

# Button properties
my $button = $object->find_first(
	isa => 'FBP::Button',
);
isa_ok( $button, 'FBP::Button' );
is( $button->id,            'wxID_ANY',  '->id ok'            );
is( $button->name,          'm_button1', '->name ok'          );
is( $button->label,         'MyButton',  '->label ok'         );
is( $button->default,       '0',         '->default ok'       );
is( $button->OnButtonClick, 'm_button1', '->OnButtonClick ok' );
