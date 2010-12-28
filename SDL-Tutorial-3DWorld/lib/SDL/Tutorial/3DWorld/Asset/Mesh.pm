package SDL::Tutorial::3DWorld::Asset::Mesh;

use 5.008;
use strict;
use warnings;
use List::MoreUtils                  ();
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Material ();

our $VERSION = '0.22';

use constant {
	VERTEX   => 0,
	MATERIAL => 1,
	UV       => 2,
	FACE     => 3,
	BOX      => 4,
};





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless [ ], $class;
	$self->[VERTEX]   = [ undef ];
	$self->[MATERIAL] = [ SDL::Tutorial::3DWorld::Material->new ];
	$self->[UV]       = [ undef ];
	$self->[FACE]     = [ ];
	$self->[BOX]      = [ ];
	return $self;
}

sub box {
	@{$_[0]->[BOX]};
}

sub max_vertex {
	my $self   = shift;
	my $vertex = $self->[VERTEX];
	return $#$vertex;
}





######################################################################
# Material Definition

# Add a new material either as full material object or a set of
# parameters that act as a delta to the previous material.
# Return the material id of the new material.
sub add_material {
	my $self    = shift;
	my $array   = $self->[MATERIAL];
	my $current = $array->[-1];

	# Save the material directly if passed an object
	if ( Params::Util::_INSTANCE($_[0], 'SDL::Tutorial::3DWorld::Material') ) {
		my $material = shift;
		push @$array, $material;
		return $#$array;
	}

	# Apply the provided changes
	my %options  = @_;
	my $material = $current->clone;
	if ( exists $options{color} ) {
		$material->set_color( delete $options{color} );
	}
	if ( exists $options{texture} ) {
		$material->set_texture( delete $options{texture} );
	}
	if ( exists $options{ambient} ) {
		$material->set_ambient( delete $options{ambient} );
	}
	if ( exists $options{diffuse} ) {
		$material->set_diffuse( delete $options{diffuse} );
	}
	if ( exists $options{opacity} ) {
		$material->set_opacity( delete $options{opacity} );
	}
	if ( %options ) {
		die "One or more unsupported material options";	
	}

	push @$array, $material;
	return $#$array;
}





######################################################################
# Geometry Assembly

sub add_all {
	my $self = shift;
	my $i    = scalar @{ $self->[VERTEX] };
	my @v    = @{$_[0]};
	$self->[VERTEX]->[$i] = [ @v, @{$_[1]} ];
	$self->[UV]->[$i]     = $_[2];

	# Update the bounding box
	my $box  = $self->[BOX];
	unless ( @$box ) {
		@$box = ( @v, @v );
		return;
	}
	if ( $v[0] < $box->[0] ) {
		$box->[0] = $v[0];
	} elsif ( $v[0] > $box->[3] ) {
		$box->[3] = $v[0];
	}
	if ( $v[1] < $box->[1] ) {
		$box->[1] = $v[1];
	} elsif ( $v[1] > $box->[4] ) {
		$box->[4] = $v[1];
	}
	if ( $v[2] < $box->[2] ) {
		$box->[2] = $v[2];
	} elsif ( $v[2] > $box->[5] ) {
		$box->[5] = $v[2];
	}
}

sub add_vertex {
	my $self = shift;
	push @{ $self->[VERTEX] }, [ @_, 0, 0, 0 ];

	# Update the bounding box
	my $box  = $self->[BOX];
	unless ( @$box ) {
		@$box = ( @_, @_ );
		return;
	}
	if ( $_[0] < $box->[0] ) {
		$box->[0] = $_[0];
	} elsif ( $_[0] > $box->[3] ) {
		$box->[3] = $_[0];
	}
	if ( $_[1] < $box->[1] ) {
		$box->[1] = $_[1];
	} elsif ( $_[1] > $box->[4] ) {
		$box->[4] = $_[1];
	}
	if ( $_[2] < $box->[2] ) {
		$box->[2] = $_[2];
	} elsif ( $_[2] > $box->[5] ) {
		$box->[5] = $_[2];
	}
}

sub add_normal {
	my $self = shift;
	return 1;
}

sub add_uv {
	push @{ shift->[UV] }, [ @_ ];
}

sub add_triangle {
	my $self = shift;

	# Get the vertex list
	my $vs = $self->[VERTEX];
	my $v0 = $vs->[$_[0]] or die "No such vertex $_[0]";
	my $v1 = $vs->[$_[1]] or die "No such vertex $_[1]";
	my $v2 = $vs->[$_[2]] or die "No such vertex $_[2]";

	# Find vectors for two sides
	my $xa = $v0->[0] - $v1->[0];
	my $ya = $v0->[1] - $v1->[1];
	my $za = $v0->[2] - $v1->[2];
	my $xb = $v1->[0] - $v2->[0];
	my $yb = $v1->[1] - $v2->[1];
	my $zb = $v1->[2] - $v2->[2];

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Add the cross product to each vector so that
	# vertex normals are averaged in proportion to face sizes.
	$v0->[3] += $xn;
	$v1->[3] += $xn;
	$v2->[3] += $xn;
	$v0->[4] += $yn;
	$v1->[4] += $yn;
	$v2->[4] += $yn;
	$v0->[5] += $zn;
	$v1->[5] += $zn;
	$v2->[5] += $zn;

	# Add the face to the face list
	push @{ $self->[FACE] }, [ @_ ];
}

sub add_quad {
	my $self = shift;

	# Get the vertex list
	my $vs = $self->[VERTEX];
	my $v0 = $vs->[$_[0]] or die "No such vertex $_[0]";
	my $v1 = $vs->[$_[1]] or die "No such vertex $_[1]";
	my $v2 = $vs->[$_[2]] or die "No such vertex $_[2]";
	my $v3 = $vs->[$_[3]] or die "No such vertex $_[3]";

	# Find vectors for two sides
	my $xa = $v0->[0] - $v1->[0];
	my $ya = $v0->[1] - $v1->[1];
	my $za = $v0->[2] - $v1->[2];
	my $xb = $v1->[0] - $v2->[0];
	my $yb = $v1->[1] - $v2->[1];
	my $zb = $v1->[2] - $v2->[2];

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Add the cross product to each vector so that
	# vertex normals are averaged in proportion to face sizes.
	$v0->[3] += $xn;
	$v1->[3] += $xn;
	$v2->[3] += $xn;
	$v3->[3] += $xn;
	$v0->[4] += $yn;
	$v1->[4] += $yn;
	$v2->[4] += $yn;
	$v3->[4] += $yn;
	$v0->[5] += $zn;
	$v1->[5] += $zn;
	$v2->[5] += $zn;
	$v3->[5] += $zn;

	# Add the face to the face list
	push @{ $self->[FACE] }, [ @_ ];
}





######################################################################
# Engine Methods

# If we enable GL_NORMALIZE then we don't need this slower Perl version
sub init {
	my $self   = shift;
	my $vertex = $self->[VERTEX];
	my $box    = $self->[BOX];

	# Normalise the surface vectors
	foreach my $i ( 1 .. $#$vertex ) {
		my $v = $vertex->[$i];
		my $l = sqrt( ($v->[3] ** 2) + ($v->[4] ** 2) + ($v->[5] ** 2) ) || 1;
		$v->[3] /= $l;
		$v->[4] /= $l;
		$v->[5] /= $l;
	}

	# Initialise the materials used by the mesh.
	foreach my $material ( @{$self->[MATERIAL]} ) {
		$material->init;
	}

	
	return 1;
}

sub display {
	my $self  = shift;

	# Set up and apply defaults
	my $begin    = 0;
	my $material = 0;
	$self->[MATERIAL]->[$material]->display;

	# Render the faces
	foreach my $face ( @{$self->[FACE]} ) {
		if ( @$face == 5 ) {
			my ( $m                 ) = $face->[4];
			my ( $v0, $v1, $v2, $v3 ) = @{$self->[VERTEX]}[@$face];
			my ( $t0, $t1, $t2, $t3 ) = @{$self->[UV]}[@$face];

			# End drawing mode if needed
			if ( $begin == 3 or $m != $material ) {
				OpenGL::glEnd();
				$begin = 0;
			}

			# Switch materials between geometry sequences
			if ( $m != $material ) {
				$material = $m;
				$self->[MATERIAL]->[$material]->display;
			}

			# Start the new geometry sequence
			unless ( $begin ) {
				OpenGL::glBegin( OpenGL::GL_QUADS );
				$begin = 4;
			}

			# Draw the quad
			OpenGL::glTexCoord2f( @$t0 ) if $t0;
			OpenGL::glNormal3f( @$v0[3..5] );
			OpenGL::glVertex3f( @$v0[0..2] );
			OpenGL::glTexCoord2f( @$t1 ) if $t0;
			OpenGL::glNormal3f( @$v1[3..5] );
			OpenGL::glVertex3f( @$v1[0..2] );
			OpenGL::glTexCoord2f( @$t2 ) if $t0;
			OpenGL::glNormal3f( @$v2[3..5] );
			OpenGL::glVertex3f( @$v2[0..2] );
			OpenGL::glTexCoord2f( @$t3 ) if $t0;
			OpenGL::glNormal3f( @$v3[3..5] );
			OpenGL::glVertex3f( @$v3[0..2] );

		# We only support triangles and quads
		} else {
			my ( $m            ) = $face->[3];
			my ( $v0, $v1, $v2 ) = @{$self->[VERTEX]}[@$face];
			my ( $t0, $t1, $t2 ) = @{$self->[UV]}[@$face];

			# End drawing mode if needed
			if ( $begin == 4 or $m != $material ) {
				OpenGL::glEnd();
				$begin = 0;
			}

			# Switch materials between geometry sequences
			if ( $m != $material ) {
				$material = $m;
				$self->[MATERIAL]->[$material]->display;
			}

			# Start the new geometry sequence
			unless ( $begin ) {
				OpenGL::glBegin( OpenGL::GL_TRIANGLES );
				$begin = 3;
			}

			# Draw the triangle
			OpenGL::glTexCoord2f( @$t0 ) if $t0;
			OpenGL::glNormal3f( @$v0[3..5] );
			OpenGL::glVertex3f( @$v0[0..2] );
			OpenGL::glTexCoord2f( @$t1 ) if $t1;
			OpenGL::glNormal3f( @$v1[3..5] );
			OpenGL::glVertex3f( @$v1[0..2] );
			OpenGL::glTexCoord2f( @$t2 ) if $t2;
			OpenGL::glNormal3f( @$v2[3..5] );
			OpenGL::glVertex3f( @$v2[0..2] );

		}
	}

	# Clean up the final drawing mode
	OpenGL::glEnd() if $begin;

	return 1;
}

1;
