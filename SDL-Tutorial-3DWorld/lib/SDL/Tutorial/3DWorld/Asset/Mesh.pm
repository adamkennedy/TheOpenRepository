package SDL::Tutorial::3DWorld::Asset::Mesh;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Material ();

our $VERSION = '0.21';

use constant {
	VERTEX   => 0,
	MATERIAL => 1,
	FACE     => 2,
};

# Default material
use vars qw{ $DEFAULT_MATERIAL };
BEGIN {
	$DEFAULT_MATERIAL = SDL::Tutorial::3DWorld::Material->new;
	$DEFAULT_MATERIAL->init;
}





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless [
		[ undef ],
		[ ],
		[ ],
	], $class;
	return $self;
}





######################################################################
# Geometry Assembly

sub vertex {
	push @{ shift->[VERTEX] }, [ @_, 0, 0, 0 ];
}

sub triangle {
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
	push @{ $self->[FACE] }, \@_;
}

sub quad {
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
	push @{ $self->[FACE] }, \@_;
}





######################################################################
# Rendering and Postprocessing

# If we enable GL_NORMALIZE then we don't need this slower Perl version
# sub normalise {
	# my $self = shift;
	# foreach my $v ( @{$self->[VERTEX]} ) {
		# my $l = sqrt( ($v->[0] ** 2) + ($v->[1] ** 2) + ($v->[2] ** 2) ) || 1;
		# $v->[0] /= $l;
		# $v->[1] /= $l;
		# $v->[2] /= $l;
	# }
	# return 1;
# }

sub display {
	my $self  = shift;
	my $begin = 0;

	# Autonormalisation is normally disabled as it is expensive
	OpenGL::glEnable( OpenGL::GL_NORMALIZE );

	# Texturing might be enabled, so disable it
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );

	# Apply the default material
	$DEFAULT_MATERIAL->display;

	foreach my $face ( @{$self->[FACE]} ) {
		if ( @$face == 3 ) {
			# Switch drawing mode if needed
			OpenGL::glEnd()                         if $begin == 4;
			OpenGL::glBegin( OpenGL::GL_TRIANGLES ) if $begin != 3;
			$begin = 3;

			# Draw the triangle
			my ($v0, $v1, $v2) = @{$self->[VERTEX]}[@$face];
			OpenGL::glNormal3f( @$v0[3..5] );
			OpenGL::glVertex3f( @$v0[0..2] );
			OpenGL::glNormal3f( @$v1[3..5] );
			OpenGL::glVertex3f( @$v1[0..2] );
			OpenGL::glNormal3f( @$v2[3..5] );
			OpenGL::glVertex3f( @$v2[0..2] );

		# We only support triangles and quads
		} else {
			# Switch drawing mode if needed
			OpenGL::glEnd()                     if $begin == 3;
			OpenGL::glBegin( OpenGL::GL_QUADS ) if $begin != 4;
			$begin = 4;

			# Draw the quad
			my ($v0, $v1, $v2, $v3) = @{$self->[VERTEX]}[@$face];
			OpenGL::glNormal3f( @$v0[3..5] );
			OpenGL::glVertex3f( @$v0[0..2] );
			OpenGL::glNormal3f( @$v1[3..5] );
			OpenGL::glVertex3f( @$v1[0..2] );
			OpenGL::glNormal3f( @$v2[3..5] );
			OpenGL::glVertex3f( @$v2[0..2] );
			OpenGL::glNormal3f( @$v3[3..5] );
			OpenGL::glVertex3f( @$v3[0..2] );

		}
	}

	# Clean up the final drawing mode
	OpenGL::glEnd() if $begin;

	# Clean up drawing mode changes
	OpenGL::glDisable( OpenGL::GL_NORMALIZE );

	return 1;
}

1;
