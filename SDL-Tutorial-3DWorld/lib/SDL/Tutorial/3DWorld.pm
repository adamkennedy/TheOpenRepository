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
use OpenGL 0.64;
use SDL    2.524;
use SDLx::App                         ();
use SDL::Tutorial::3DWorld::Light     ();
use SDL::Tutorial::3DWorld::Actor     ();
use SDL::Tutorial::3DWorld::Camera    ();
use SDL::Tutorial::3DWorld::Landscape ();

our $VERSION = '0.01';

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

	# Create the landscape
	$self->{landscape} = SDL::Tutorial::3DWorld::Landscape->new;

	# Light the scene with a single overhead light
	$self->{lights} = [
		SDL::Tutorial::3DWorld::Light->new(
			X => 0,
			Y => 10,
			Z => 0,
		),
	];

	# Place three airborn stationary teapots in the scene
	$self->{actors} = [
		SDL::Tutorial::3DWorld::Actor->new(
			X => 0,
			Y => 0.5,
			Z => 0,
		),
		SDL::Tutorial::3DWorld::Actor->new(
			X => 0,
			Y => 1,
			Z => 0,
		),
		SDL::Tutorial::3DWorld::Actor->new(
			X => 0,
			Y => 0.5,
			Z => 0,
		),
	];

	# Place the camera at a typical eye height a few metres back
	# from the teapots and facing slightly down towards it.
	$self->{camera} = SDL::Tutorial::3DWorld::Camera->new(
		X => 0,
		Y => 1.5,
		Z => -5,
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
	OpenGL::glEnable( GL_DEPTH_TEST );

	# Lets use smooth shading so we look a bit fancier
	OpenGL::glShadeModel( GL_SMOOTH );

	# Initialise the camera so we are looking at something
	$self->{camera}->init( $self->{width}, $self->{height} );

	# Initialise the landscape so there is a world
	$self->{landscape}->init;

	# We don't need to initialise the lights or actors (yet)

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
