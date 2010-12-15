package SDL::Tutorial::3DWorld;

=pod

=head1 NAME

SDL::Tutorial::3DWorld - Demonstrates a very basic 3D engine

=head1 DESCRIPTION

This tutorial is intended to demonstrate the creation of a trivial but
relatively usable "3D Game Engine".

The demonstration code provided implements the four main elements of a
basic three-dimensional game world.

=over

=item *

A static landscape in which events will occur.

=item *

A light source to illuminate the world.

=item *

A collection of N objects which move around independantly inside the
world.

=item *

A user-controlled mobile camera through which the world is viewed

=back

Each element of the game world is encapsulated inside a standalone class.

This lets you see which parts of the Open GL operations are used to work
with each element of the game world, and provides a starting point from
which you can start to make your own simple game-specific engines.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use File::Spec                   0.80 ();
use File::ShareDir               1.02 ();
use OpenGL                       0.64 ':all';
use SDL                         2.524 ':all';
use SDL::Event                        ':all';
use SDLx::App                         ();
use SDL::Tutorial::3DWorld::Light     ();
use SDL::Tutorial::3DWorld::Actor     ();
use SDL::Tutorial::3DWorld::Camera    ();
use SDL::Tutorial::3DWorld::Skybox    ();
use SDL::Tutorial::3DWorld::Texture   ();
use SDL::Tutorial::3DWorld::Landscape ();

our $VERSION = '0.06';

=pod

=head2 new

The C<new> constructor sets up the model for the 3D World, but does not
initiate or start the game itself.

It does not current take any parameters.

=cut

sub new {
	my $class = shift;
	my $self  = bless {
		width  => 800,
		height => 600,
	}, $class;

	# A pretty skybox background for our world
	$self->{skybox} = SDL::Tutorial::3DWorld::Skybox->new(
		type      => 'jpg',
		directory => File::Spec->catdir(
			File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
			'skybox',
		),
	);

	# Create the landscape
	$self->{landscape} = SDL::Tutorial::3DWorld::Landscape->new;

	# Place three airborn stationary teapots in the scene
	$self->{actors} = [
		SDL::Tutorial::3DWorld::Actor->new(
			X => 0,
			Y => 0.5,
			Z => 0,
			velocity => [ 0, 0, 0.001 ],
		),
		SDL::Tutorial::3DWorld::Actor->new(
			X => 0,
			Y => 1,
			Z => 0,
			velocity => [ 0.001, 0, 0 ],
		),
		SDL::Tutorial::3DWorld::Actor->new(
			X => 0,
			Y => 1.5,
			Z => 0,
			velocity => [ 0, 0.001, 0 ],
		),
	];

	# Light the world with a single overhead light
	$self->{lights} = [
		SDL::Tutorial::3DWorld::Light->new(
			X => 100,
			Y => 100,
			Z => 100,
		),
	];

	# Place the camera at a typical eye height a few metres back
	# from the teapots and facing slightly down towards it.
	$self->{camera} = SDL::Tutorial::3DWorld::Camera->new(
		X => 0,
		Y => 1.5,
		Z => 5,
	);

	return $self;
}

=pod

=head2 run

The C<run> method is used to run the game. It takes care of all stages of
the game including initialisation and shutdown operations at the start
and end of the game.

=cut

sub run {
	my $self = shift;

	# Initialise the game
	$self->init;

	# Render handler
	$self->{sdl}->add_show_handler( sub {
		$self->display(@_);
		$self->sync;
	} );

	# Event handler
	$self->{sdl}->add_event_handler( sub {
		$self->event(@_);
	} );

	# Enter the main loop
	$self->{sdl}->run;

	return 1;
}





######################################################################
# Internal Methods

sub init {
	my $self = shift;

	# Create the SDL application object
	$self->{sdl} = SDLx::App->new(
		title  => '3D World',
		width  => $self->{width},
		height => $self->{height},
		gl     => 1,
	);

	# Enable the Z buffer (DEPTH BUFFER) so that OpenGL will do all the
	# correct shape culling for us and we don't have to care about it.
	glEnable( GL_DEPTH_TEST );

	# Make shading prettier
	glShadeModel( GL_SMOOTH );

	# If we have any lights, initialise lighting
	if ( @{$self->{lights}} ) {
		glEnable( GL_LIGHTING );
	}

	# Initialise the camera so we can look at things
	$self->{camera}->init( $self->{width}, $self->{height} );

	# Initialise and load the skybox
	if ( $self->{skybox} ) {
		$self->{skybox}->init;
	}

	# Initialise the landscape so there is a world
	$self->{landscape}->init;

	# Enable GLUT support so we can have teapots
	OpenGL::glutInit();

	# Initialise the actors (probably nothing to do though)
	foreach my $actor ( @{$self->{actors}} ) {
		$actor->init;
	}

	return 1;
}

# This is the primary render loop
sub display {
	my $self = shift;

	# Reset the model, throwing away the previously calculated scene
	# and starting again with a blank sky.
	$self->clear;
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();

	# Move the camera to the required position.
	# NOTE: For now just translate back so we can see the render.
	$self->{camera}->display;

	# Draw the skybox.
	# It needs to know where the camera is to do it's special effect
	if ( $self->{skybox} ) {
		$self->{skybox}->display( $self->{camera} );
	}

	# Draw the landscape
	$self->{landscape}->display;

	# Draw the lights
	foreach my $light ( @{$self->{lights}} ) {
		$light->display;
	}

	# Draw each of the actors in the scene
	foreach my $actor ( @{$self->{actors}} ) {
		# Draw each actor in their own stack context so that
		# their transform operations do not effect anything else.
		glPushMatrix();
		$actor->display;
		glPopMatrix();
	}

	return 1;
}

sub event {
	my $self  = shift;
	my $event = shift;
	my $type  = $event->type;

	# Quit option
	if ( $type == SDL_KEYDOWN ) {
		my $key = $event->key_sym;
		if ( $key == SDLK_ESCAPE ) {
			$self->{sdl}->stop;
			return 1;
		}
	}

	# Handle any events related to the camera
	$self->{camera}->event($event) and return 1;

	return 1;
}





######################################################################
# Utility Methods

# Clear the colour buffer (what we actually see) and the depth buffer
# (the area GL uses to remove things behind other things).
# This gives us a blank screen with our chosen sky colour.
sub clear {
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}

# This is a convenience method.
# Pass through to the version in the SDL app
sub sync {
	$_[0]->{sdl}->sync;
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
