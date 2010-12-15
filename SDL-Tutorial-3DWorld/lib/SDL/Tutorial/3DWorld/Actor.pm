package SDL::Tutorial::3DWorld::Actor;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor - A moving object within the game world

=head1 SYNOPSIS

  # Create a vertical stack of teapots
  my @stack = ();
  foreach my $height ( 1 .. 10 ) {
      push @stack, SDL::Tutorial::3DWorld::Actor->new(
          X => 0,
          Y => $height * 0.30, # Each teapot is 30cm high
          Z => 0,
      );
  }

=head1 DESCRIPTION

Within the game, the term "Actor" is used to describe anything that has
a shape and moves around the world based on it's own set of rules.

In practice, an actor could be anything from a bullet or a grenade flying
through the air, to a fully articulated roaring dragon with flaming breath
and it's own artificial intelligence.

To the game engine, all of these "actors" are basically the same. They are
merely things that need to describe where they are and what they look like
each time the engine wants to render a frame.

In this demonstration, the default actor is a 30cm x 30cm teapot. We are
using a teapot because it is the "official" test mesh object for OpenGL
and is built directly into the library itself via the C<glutCreateTeapot>
function.

=head1 METHODS

=cut

use strict;
use warnings;
use OpenGL;

our $VERSION = '0.05';

=head2 new

  my $teapot = SDL::Tutorial::3DWorld::Actor->new;

The C<new> constructor is used to create a new actor within the 3D World.

In the demonstration implementation, the default actor consists of a teapot.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Default location is at the origin
	$self->{X} ||= 0;
	$self->{Y} ||= 0;
	$self->{Z} ||= 0;

	return $self;
}

=pod

=head2 X

The C<X> accessor provides the location of the actor in metres on the east
to west dimension within the 3D world. The positive direction is east.

=cut

sub X {
	$_[0]->{X};
}

=pod

=head2 Y

The C<Y> accessor is location of the actor in metres on the vertical
dimension within the 3D world. The positive direction is up.

=cut

sub Y {
	$_[0]->{Y};
}

=pod

=head2 Z

The C<Z> accessor provides the actor of the camera in metres on the north
to south dimension within the 3D world. The positive direction is north.

=cut

sub Z {
	$_[0]->{Z};
}





######################################################################
# Engine Interface

sub init {
	return 1;
}

sub display {
	my $self = shift;

	# Translate by the position of the actor
	glTranslatef( $self->X, $self->Y, $self->Z );

	# Draw a untextured greenish teapot
	glDisable( GL_TEXTURE_2D );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_AMBIENT, 0.5, 0.7, 0.5, 0.5 );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_DIFFUSE, 0.5, 0.7, 0.5, 0.5 );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, 1, 1, 1, 1 );
	OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, 80 );
	OpenGL::glutSolidTeapot(0.3);

	return 1;
}

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
