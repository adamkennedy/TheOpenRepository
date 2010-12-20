#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	# $^W = 1; # Model3D::WavefrontObject doesn't pass with warnings
}

use Test::More tests => 4;
use Test::NoWarnings;
use File::Spec               ();
use Model3D::WavefrontObject ();

# Location of the test file
my $file = File::Spec->catfile('share', 'model', 'table', 'table.obj');
ok( -f $file, "Found test file '$file'" );

# Load using the ordinary loader
my $model3d = Model3D::WavefrontObject->new;
isa_ok( $model3d, 'Model3D::WavefrontObject' );
ok( $model3d->ReadObj($file), '->ReadObj ok' );
