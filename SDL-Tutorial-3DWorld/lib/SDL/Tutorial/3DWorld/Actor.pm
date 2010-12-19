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

our $VERSION = '0.18';

=head2 new

  my $teapot = SDL::Tutorial::3DWorld::Actor->new;

The C<new> constructor is used to create a new actor within the 3D World.

In the demonstration implementation, the default actor consists of a teapot.

=cut

sub new {
	my $class = shift;
	my $self  = bless {
		# Default location is at the origin
		X         => 0,
		Y         => 0,
		Z         => 0,

		# Most things in the world don't move by default
		velocity  => [ 0, 0, 0 ],

		# 3D worlds are clinical, white and shiny by default
		ambient   => [ 0.2, 0.2, 0.2, 1.0 ],
		diffuse   => [ 0.8, 0.8, 0.8, 1.0 ],
		specular  => [ 1.0, 1.0, 1.0, 1.0 ],
		shininess => 100,

		# Override defaults
		@_,
	}, $class;

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
	return;
}

sub display {
	my $self = shift;

	# Translate to the position of the actor
	glTranslatef( $self->X, $self->Y, $self->Z );

	return;
}

sub move {
	my $self = shift;
	my $step = shift;

	# If it has velocity, change the actor's position
	$self->{X} += $self->{velocity}->[0] * $step;
	$self->{Y} += $self->{velocity}->[1] * $step;
	$self->{Z} += $self->{velocity}->[2] * $step;

	return;
}





######################################################################
# Support Methods

sub display_material {
	my $self = shift;

	# Configure the material properties
	OpenGL::glMaterialfv_p( GL_FRONT, GL_AMBIENT, @{$self->{ambient}} );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_DIFFUSE, @{$self->{diffuse}} );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, @{$self->{specular}} );
	OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, $self->{shininess} );

	return;
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
