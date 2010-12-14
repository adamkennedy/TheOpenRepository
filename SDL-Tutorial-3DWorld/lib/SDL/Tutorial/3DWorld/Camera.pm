package SDL::Tutorial::3DWorld::Camera;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Camera - A movable viewpoint in the game world

=head1 SYNOPSIS

  # Start the camera 1.5 metres above the ground, 10 metres back from
  # the world origin, looking north and slightly downwards.
  my $camera = SDL::Tutorial::3DWorld::Camera->new(
      X         => 0,
      Y         => 1.5,
      Z         => 10,
      angle     => 0,
      elevation => -5,
  };

=head1 DESCRIPTION

The B<SDL::Tutorial::3DWorld::Camera> represents the viewpoint that the
user controls to move through the 3D world.

In this initial skeleton code, the camera is fixed and cannot be moved.

=head1 METHODS

=cut

use strict;
use warnings;
use OpenGL ();

our $VERSION = '0.01';

=pod

=head2 new

  # Start the camera at the origin, facing north and looking at the horizon
  my $camera = SDL::Tutorial::3DWorld::Camera->new(
      X         => 0,
      Y         => 0,
      Z         => 0,
      angle     => 0,
      elevation => 0,
  };

The C<new> constructor creates a camera that serves as the primary
abstraction for the viewpoint as it moves through the world.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# The default position of the camera is at 0,0,0 facing north
	$self->{X}         ||= 0;
	$self->{Y}         ||= 0;
	$self->{Z}         ||= 0;
	$self->{angle}     ||= 0;
	$self->{elevation} ||= 0;

	return $self;
}

=pod

=head2 X

The C<X> accessor provides the location of the camera in metres on the east
to west dimension within the 3D world. The positive direction is east.

=cut

sub X {
	$_[0]->{X};
}

=pod

=head2 Y

The C<Y> accessor is location of the camera in metres on the vertical
dimension within the 3D world. The positive direction is up.

=cut

sub Y {
	$_[0]->{Y};
}

=pod

=head2 Z

The C<Z> accessor provides the location of the camera in metres on the north
to south dimension within the 3D world. The positive direction is north.

=cut

sub Z {
	$_[0]->{Z};
}

=pod

=head2 angle

The C<angle> accessor provides the direction the camera is facing on the
horizontal plane within the 3D world. Positive indicates clockwise degrees
from north. Thus C<0> is north, C<90> is east, C<180> is south and C<270>
is west.

The C<angle> is more correctly known as the "azimuth" but we prefer the
simpler common term for a gaming API. For more details see
L<http://en.wikipedia.org/wiki/Azimuth>.

=cut

sub angle {
	$_[0]->{angle};
}

=pod

=head2 elevation

The C<elevation> accessor provides the direction the camera is facing on
the vertical plane. Positive indicates degrees above the horizon. Thus
C<0> is looking at the horizon, C<90> is facing straight up, and
C<-90> is facing straight down.

The C<elevation> is more correctly known as the "altitude" but we prefer the
simpler common term for a gaming API. For more details see
see L<http://en.wikipedia.org/w/index.php?title=Altitude_(astronomy)>.

=cut

sub elevation {
	$_[0]->{elevation};
}





######################################################################
# Engine Interface

sub init {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	# Select and reset the projection
	OpenGL::glMatrixMode( OpenGL::GL_PROJECTION );
	OpenGL::glLoadIdentity();

	# Set the perspective we will look through.
	# We'll use a standard 60 degree perspective, removing any
	# shapes closer than one metre or further than one kilometre.
	OpenGL::gluPerspective( 60, $width / $height, 1, 1000 );

	return 1;
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
