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
use OpenGL;
use SDL::Mouse;
use SDL::Constants ();

use constant D2R => CORE::atan2(1,1) / 40;

our $VERSION = '0.02';

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

	# Flag to allow mouse motion events in situations where we know
	# that the first event following some particular event will be bad.
	# We always ignore the first motion event at startup.
	$self->{ignore_motion} = 1;

	# Key tracking
	$self->{down} = {
		# Move camera forwards and backwards
		SDL::Constants::SDLK_w => 0,
		SDL::Constants::SDLK_s => 0,

		# Strafe camera left and right
		SDL::Constants::SDLK_a => 0,
		SDL::Constants::SDLK_d => 0,

		# Rotate camera left and right
		SDL::Constants::SDLK_q => 0,
		SDL::Constants::SDLK_e => 0,
	};

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

# Note that this doesn't position the camera, just sets it up
sub init {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	# Select and reset the projection, flushing any old state
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();

	# Set the perspective we will look through.
	# We'll use a standard 60 degree perspective, removing any
	# shapes closer than one metre or further than one kilometre.
	gluPerspective( 45.0, $width / $height, 0.1, 1000 );

	# As a mouselook game, we don't want users to see the cursor
	SDL::Mouse::show_cursor( SDL::Constants::SDL_DISABLE );

	return 1;
}

sub display {
	my $self  = shift;
	my $down  = $self->{down};

	# Apply camera direction from keyboard
	$self->{angle} += (
		$down->{SDL::Constants::SDLK_e} -
		$down->{SDL::Constants::SDLK_q}
	);
	$self->{angle} = $self->{angle} - 360 * int($self->{angle} / 360);

	# Update the camera location
	my $speed  = 0.1;
	my $move   = $speed * (
		$down->{SDL::Constants::SDLK_s} -
		$down->{SDL::Constants::SDLK_w}
	);
	my $strafe = $speed * (
		$down->{SDL::Constants::SDLK_d} -
		$down->{SDL::Constants::SDLK_a}
	);

	# Apply movement in the direction of the camera
	my $angle = $self->{angle} * D2R;
	$self->{X} += (cos($angle) * $strafe) - (sin($angle) * $move);
	$self->{Z} += (sin($angle) * $strafe) + (cos($angle) * $move);

	glRotatef( $self->{elevation}, 1, 0, 0 );
	glRotatef( $self->{angle},     0, 1, 0 );
	glTranslatef( -$self->X, -$self->Y, -$self->Z );
}

sub event {
	my $self  = shift;
	my $event = shift;
	my $type  = $event->type;

	if ( $type == SDL::Constants::SDL_MOUSEMOTION ) {
		if ( $self->{ignore_motion} ) {
			$self->{ignore_motion} = 0;
			return 1;
		}
		my $x = $event->motion_xrel;
		my $y = $event->motion_yrel;
		$x = $x - 65536 if $x > 32000;
		$y = $y - 65536 if $y > 32000;
		$self->{angle}     += $x / 5;
		$self->{elevation} += $y / 10;
		$self->{elevation} =  90 if $self->{elevation} >  90;
		$self->{elevation} = -90 if $self->{elevation} < -90;
		return 1;
	}

	if ( $type == SDL::Constants::SDL_KEYDOWN ) {
		my $key = $event->key_sym;
		if ( exists $self->{down}->{$key} ) {
			$self->{down}->{$key} = 1;
			return 1;
		}
	}

	if ( $type == SDL::Constants::SDL_KEYUP ) {
		my $key = $event->key_sym;
		if ( exists $self->{down}->{$key} ) {
			$self->{down}->{$key} = 0;
			return 1;
		}
	}

	return 0;
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
