package SDL::Tutorial::3DWorld::Actor::TextureCube;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::TextureCube - Crates, companions and more...

=head1 DESCRIPTION

The C<TextureCube> is one of the staples of classic 3D games.

Most famously, it can be used to create the ubiquitous and stereotypical
crate model from classic first person shooters like Quake.

Since this is a relatively practical class you might actually realistically
use in a 3D world in large numbers we will also attempt to make use of
simple straight forward optimisation methods to get the cubes drawing
relatively quickly.

For convenience when stacking, the original on a C<TextureCube> is located
at the centre of the bottom face of the cube. So given a surface plane at
the original, a C<TextureCube> located at the origin will in effect be
sitting "on" the plane.

=head1 METHODS

=cut

use strict;
use warnings;
use OpenGL;
use OpenGL::List                     ();
use Params::Util                     '_INSTANCE';
use SDL::Tutorial::3DWorld::Actor    ();
use SDL::Tutorial::3DWorld::Texture  ();
use SDL::Tutorial::3DWorld::Material ();

our $VERSION = '0.23';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

=pod

=head2 new

  # Sweet crate, familiar crate, err... flying crate?
  my $crate = SDL::Tutorial::3DWorld::Actor::TextureCube->new(
      size     => 2,
      velocity => [ 0.0, 1.0, 0.1 ],
      material => {
          texture  => File::Spec->catfile(
              File::ShareDir::dist_dir('SDL::Tutorial::3DWorld'),
              'crate1.jpg',
          ),
      ),
  );

The C<new> constructor creates a new textured cube.

In addition to the usual L<SDL::Tutorial::3DWorld::Actor> parameters,
it takes some additional parameters.

The C<size> parameter is the size of the cube in metres. Cubes grow in
size upwards from the base in the vertical plane, and outwards from the
centre on the horizontal plane.

The C<texture> parameter should be the name of the file containing the
texture to be used on all six sides of the cube. Alternatively, you can
if you wish pass in your own L<SDL::Tutorial::3DWorld::Texture> object.

=cut

sub new {
	my $class = shift;
	my %param = @_;
	if ( $param{texture} and not $param{material} ) {
		$param{material} = {
			texture => delete $param{texture},
		};
	}

	$class->SUPER::new( %param );
}





######################################################################
# Engine Methods

sub init {
	my $self = shift;
	my $size = $self->{size};
	$self->SUPER::init(@_);

	# Pre-compile the cube drawing code
	$self->{list} = OpenGL::List::glpList {
		$self->compile;
	};

	# Define the bounding box
	$self->{box} = [
		map { $_ * $size / 2 } ( -1, 0, -1, 1, 2, 1 )
	];

	return;
}

sub display {
	my $self  = shift;
	my $scale = $self->{size} / 2;

	# Because the superclass does the main translation of the object,
	# we need to do this after the scaling above or the translation
	# would get scaled too (i.e. NOT what we want)
	$self->SUPER::display(@_);

	# To prevent having to calculate all of the measurements of
	# the cube, we apply the scaling via a single call.
	glScalef( $scale, $scale, $scale );

	# Call the compiled form of the draw method below that has been
	# pre-compiled into the OpenGL context.
	glCallList( $self->{list} );
}

# Compile the drawing instructions for the cube into an OpenGL
# "display list" (which is basically just a macro in GL terms).
# Using a list instead of manually doing each vector will remove
# off all of the Perl overheads, and even some of the C overheads.
sub compile {
	my $self = shift;

	# Set up the material
	$self->{material}->display;

	# Draw each of the quads for the cube
	# NOTE: This is hardly "optimised" but will at least get us a
	# working cube fairly quickly.
	glBegin( GL_QUADS );

	# Draw the north face
	glNormal3f( 0, 0, -1 );
	glTexCoord2f( 0, 0 ); glVertex3f(  1,  2, -1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f(  1,  0, -1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f( -1,  0, -1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f( -1,  2, -1 ); # Top Right

	# Draw the east face
	glNormal3f( 1, 0, 0 );
	glTexCoord2f( 0, 0 ); glVertex3f(  1,  2,  1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f(  1,  0,  1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f(  1,  0, -1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f(  1,  2, -1 ); # Top Right

	# Draw the south face
	glNormal3f( 0, 0, 1 );
	glTexCoord2f( 0, 0 ); glVertex3f( -1,  2,  1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f( -1,  0,  1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f(  1,  0,  1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f(  1,  2,  1 ); # Top Right

	# Draw the west face
	glNormal3f( -1, 0, 0 );
	glTexCoord2f( 0, 0 ); glVertex3f( -1,  2, -1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f( -1,  0, -1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f( -1,  0,  1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f( -1,  2,  1 ); # Top Right

	# Draw the up face
	glNormal3f( 0, 1, 0 );
	glTexCoord2f( 0, 0 ); glVertex3f(  1,  2,  1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f(  1,  2, -1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f( -1,  2, -1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f( -1,  2,  1 ); # Top Right

	# Draw the down face
	glNormal3f( 0, -1, 0 );
	glTexCoord2f( 0, 0 ); glVertex3f(  1,  0, -1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f(  1,  0,  1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f( -1,  0,  1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f( -1,  0, -1 ); # Top Right

	# Finish drawing
	glEnd();
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDL-Tutorial-3DWorld>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<SDL>, L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
