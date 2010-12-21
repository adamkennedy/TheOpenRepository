#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Test::NoWarnings;
use File::Spec                         ();
use SDL::Tutorial::3DWorld::Asset::OBJ ();

# Location of the test file
my $file = File::Spec->catfile('share', 'model', 'table', 'table.obj');
ok( -f $file, "Found test file '$file'" );

SCOPE: {
	# Create the ::OBJ object
	my $obj = new_ok( 'SDL::Tutorial::3DWorld::Asset::OBJ', [
		file => $file,
	], 'Created OBJ object' );

	# Initialise the OBJ object
	ok( $obj->init, '->init ok' );
	ok( defined $obj->list, '->list ok' );
	isa_ok( $obj->asset, 'SDL::Tutorial::3DWorld::Asset' );
	like(
		$obj->asset->directory,
		qr/\btable$/,
		'->asset refers to the correct directory',
	);
}

# SCOPE: {
	# Load using the ordinary loader
	# my $model3d = Model3D::WavefrontObject->new;
	# isa_ok( $model3d, 'Model3D::WavefrontObject' );
	# ok( $model3d->ReadObj($file), '->ReadObj ok' );
# }
