package SDL::Tutorial::3DWorld::Actor::GridCube;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::GridCube - A grid-snapping 3D wireframe cube

=head1 DESCRIPTION

The B<GridCube> is a 1 metre white wireframe cube which will track it's
position in float terms and can be moved around the game world like any
other actor, but which will draw itself snapped to an imaginary 1 metre
grid.

The position of the cube will be moved to ensure that the actual floating
point location of the actor is inside the cube.

If the location of the cube is an exact integer, the cube will be located
on the positive axis side (in all three dimension) of the actor position.

=cut

use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL ();
use SDL::Tutorial::3DWorld::Actor  ();

# Use proper POSIX math rather than playing games with Perl's int()
use POSIX ();

our $VERSION = '0.18';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Engine Interface

sub display {
	my $self = shift;

	# Where is the cube source floating location
	my $X = $self->X;
	my $Y = $self->Y;
	my $Z = $self->Z;

	# The cube is plain opaque full-bright white and ignores lighting
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );
	OpenGL::glColor4f( 1, 1, 1, 1 );

	# Draw a point actual X,Y,Z position is
	OpenGL::glPointSize( 5 );
	OpenGL::glBegin( OpenGL::GL_POINTS );
	OpenGL::glVertex3f( $X, $Y, $Z );
	OpenGL::glEnd();

	# Snap the current floating position to the 1 metre (integer) grid
	my $L = POSIX::floor($X); # (L)eft
	my $D = POSIX::floor($Y); # (D)own
	my $F = POSIX::floor($Z); # (F)ront
	my $R = POSIX::ceil($X);  # (R)ight
	my $U = POSIX::ceil($Y);  # (U)p
	my $B = POSIX::ceil($Z);  # (B)ack

	# For some reason, this particular function is incredibly
	# expensive according to NYTProf.
	OpenGL::glLineWidth( 1 );

	# Draw the lines that make up the cube.
	# We'll do this longhand to make it clear how much work can be
	# involved in hand-drawning something. In practice you would
	# probably use a tuned and optimised alternative, or just
	# translate and call C<glutCube> or load a saved model.
	OpenGL::glBegin( OpenGL::GL_LINES );
	OpenGL::glVertex3f( $L, $D, $F ); OpenGL::glVertex3f( $R, $D, $F );
	OpenGL::glVertex3f( $L, $D, $F ); OpenGL::glVertex3f( $L, $U, $F );
	OpenGL::glVertex3f( $L, $D, $F ); OpenGL::glVertex3f( $L, $D, $B );
	OpenGL::glVertex3f( $R, $D, $F ); OpenGL::glVertex3f( $R, $U, $F );
	OpenGL::glVertex3f( $R, $D, $F ); OpenGL::glVertex3f( $R, $D, $B );
	OpenGL::glVertex3f( $L, $U, $F ); OpenGL::glVertex3f( $R, $U, $F );
	OpenGL::glVertex3f( $L, $U, $F ); OpenGL::glVertex3f( $L, $U, $B );
	OpenGL::glVertex3f( $L, $D, $B ); OpenGL::glVertex3f( $R, $D, $B );
	OpenGL::glVertex3f( $L, $D, $B ); OpenGL::glVertex3f( $L, $U, $B );
	OpenGL::glVertex3f( $R, $U, $F ); OpenGL::glVertex3f( $R, $U, $B );
	OpenGL::glVertex3f( $R, $D, $B ); OpenGL::glVertex3f( $R, $U, $B );
	OpenGL::glVertex3f( $L, $U, $B ); OpenGL::glVertex3f( $R, $U, $B );
	OpenGL::glEnd();

	# Lighting is on by default in our 3DWorld application.
	# Reenable it so each individual lit object doesn't have to
	# explicitly turn it on.
	OpenGL::glEnable( OpenGL::GL_LIGHTING );

	return;
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
