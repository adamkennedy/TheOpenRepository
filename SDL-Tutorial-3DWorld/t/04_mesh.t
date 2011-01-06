#!/usr/bin/perl

# General tests for the mesh abstraction

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;
use SDL::Tutorial::3DWorld::Mesh ();





######################################################################
# Main Tests

# Create a simple square
my $mesh = new_ok( 'SDL::Tutorial::3DWorld::Mesh' => [], '->new ok' );
$mesh->add_vertex( -1, 0, 2 );
$mesh->add_vertex(  1, 0, 2 );
$mesh->add_vertex(  1, 1, 2 );
$mesh->add_vertex( -1, 1, 2 );
$mesh->add_quad( 1, 2, 3, 4 );

# Does the mesh look right?
is( $mesh->max_vertex, 4, '->max_vertex ok' );
is_deeply( $mesh->box, [ -1, 0, 2, 1, 1, 2 ], '->box ok' );

# Generate an OpenGL display list
is( $mesh->as_list, 0, '->as_list ok' );
is( $mesh->as_list, 1, '->as_list multiple' );

# Generate an Vertex OGA (OpenGL::Array)
my $oga = $mesh->as_oga;
isa_ok( $oga, 'OpenGL::Array' );
