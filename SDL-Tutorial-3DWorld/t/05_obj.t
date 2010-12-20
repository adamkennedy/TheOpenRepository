#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use File::Spec                  ();
use SDL::Tutorial::3DWorld::OBJ ();

# Location of the test file
my $file = File::Spec->catfile('share', 'model', 'table', 'table.obj');
ok( -f $file, "Found test file '$file'" );

SCOPE: {
	# Create the ::OBJ object
	my $obj = new_ok( 'SDL::Tutorial::3DWorld::OBJ', [
		file => $file,
	], 'Created OBJ object' );

	# Initialise the RWX object
	ok(         $obj->init, '->init ok' );
	ok( defined $obj->list, '->list ok' );
}

# SCOPE: {
	# Load using the ordinary loader
	# my $model3d = Model3D::WavefrontObject->new;
	# isa_ok( $model3d, 'Model3D::WavefrontObject' );
	# ok( $model3d->ReadObj($file), '->ReadObj ok' );
# }
