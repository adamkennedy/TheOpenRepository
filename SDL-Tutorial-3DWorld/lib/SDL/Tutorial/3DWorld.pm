package SDL::Tutorial::3DWorld;

=pod

=head1 NAME

SDL::Tutorial::3DWorld - Create a 3D world from scratch with SDL and OpenGL

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
use IO::File                                  1.14 ();
use File::Spec                                3.31 ();
use File::ShareDir                            1.02 ();
use List::MoreUtils                           0.22 ();
use Params::Util                              1.00 ();
use OpenGL                                    0.64 ':all';
use OpenGL::List                              0.01 ();
use SDL                                      2.524 ':all';
use SDL::Event                                     ':all';
use SDLx::App                                      ();
use SDL::Tutorial::3DWorld::Actor                  ();
use SDL::Tutorial::3DWorld::Actor::Debug           ();
use SDL::Tutorial::3DWorld::Actor::Model           ();
use SDL::Tutorial::3DWorld::Actor::Teapot          ();
use SDL::Tutorial::3DWorld::Actor::GridCube        ();
use SDL::Tutorial::3DWorld::Actor::GridSelect      ();
use SDL::Tutorial::3DWorld::Actor::TextureCube     ();
use SDL::Tutorial::3DWorld::Actor::MaterialSampler ();
use SDL::Tutorial::3DWorld::Asset                  ();
use SDL::Tutorial::3DWorld::Camera                 ();
use SDL::Tutorial::3DWorld::Camera::God            ();
use SDL::Tutorial::3DWorld::Console                ();
use SDL::Tutorial::3DWorld::Landscape              ();
use SDL::Tutorial::3DWorld::Landscape::Infinite    ();
use SDL::Tutorial::3DWorld::Light                  ();
use SDL::Tutorial::3DWorld::Material               ();
use SDL::Tutorial::3DWorld::Model                  ();
use SDL::Tutorial::3DWorld::OpenGL                 ();
use SDL::Tutorial::3DWorld::Skybox                 ();
use SDL::Tutorial::3DWorld::Texture                ();

our $VERSION = '0.25';

# The currently active world
our $CURRENT = undef;

=pod

=head2 new

The C<new> constructor sets up the model for the 3D World, but does not
initiate or start the game itself.

It does not current take any parameters.

=cut

sub new {
	my $class = shift;
	my $self  = bless {
		ARGV           => [ @_ ],
		width          => 1280,
		height         => 1024,
		dt             => 0.1,

		# Debugging or expensive elements we can toggle off.
		# Turning all of these three off gives us a much more
		# accurate assessment on how fast a real world would perform.
		hide_debug     => 0,
		hide_console   => 0,
		hide_expensive => 0,
	}, $class;

	# Text console that overlays the world
	$self->{console} = SDL::Tutorial::3DWorld::Console->new;

	# A pretty skybox background for our world
	$self->{skybox} = SDL::Tutorial::3DWorld::Skybox->new(
		type      => 'jpg',
		directory => $self->sharedir('skybox'),
	);

	# Create the landscape
	$self->{landscape} = SDL::Tutorial::3DWorld::Landscape::Infinite->new(
		texture => $self->sharefile('ground.jpg'),
	);

	# Place the camera at a typical eye height a few metres back
	# from the teapots and facing slightly down towards them.
	$self->{camera} = SDL::Tutorial::3DWorld::Camera::God->new(
		X     => 0.0,
		Y     => 1.5,
		Z     => 5.0,
		speed => $self->dscalar( 2 ),
	);

	# The selector is an actor and a special camera tool for
	#(potentially) controlling something in the world.
	$self->{selector} = SDL::Tutorial::3DWorld::Actor::GridSelect->new;

	# Place three airborn stationary teapots in the scene
	my $actors = $self->{actors} = [

		# Make sure we add the selector to the actor list.
		$self->{selector},

		# (R)ed is the official colour of the X axis
		SDL::Tutorial::3DWorld::Actor::Teapot->new(
			position => [ 0.0, 0.5, 0.0 ],
			velocity => $self->dvector( 0.1, 0.0, 0.0 ),
			material => {
				ambient  => [ 0.5, 0.2, 0.2, 1.0 ],
				diffuse  => [ 1.0, 0.7, 0.7, 1.0 ],
			},
		),

		# (B)lue is the official colour of the Z axis
		SDL::Tutorial::3DWorld::Actor::Teapot->new(
			scale    => [ 1.5, 1.5, 1.5 ],
			position => [ 0.0, 1.0, 0.0 ],
			velocity => $self->dvector( 0.0, 0.0, 0.1 ),
			material => {
				ambient  => [ 0.2, 0.2, 0.5, 1.0 ],
				diffuse  => [ 0.7, 0.7, 1.0, 1.0 ],
			},
		),

		# (G)reen is the official colour of the Y axis
		SDL::Tutorial::3DWorld::Actor::Teapot->new(
			scale    => [ 2.0, 2.0, 2.0 ],
			position => [ 0.0, 1.5, 0.0 ],
			velocity => $self->dvector( 0.0, 0.1, 0.0 ),
			material => {
				ambient  => [ 0.2, 0.5, 0.2, 1 ],
				diffuse  => [ 0.7, 1.0, 0.7, 1 ],
			},
		),

		# Place a static grid cube in the air on the positive
		# and negative corners of the landscape, proving the
		# grid-bounding math works (which it might not on the
		# negative side of an axis if you mistakenly use int()
		# for the math instead of something like POSIX::ceil/floor).
		SDL::Tutorial::3DWorld::Actor::GridCube->new(
			position => [ -3.7, 1.3, -3.7 ],
		),

		# Set up a flying grid cube heading away from the teapots.
		# This should demonstrate the "grid" nature of the cube,
		# and the flying path will take us along a path that will
		# share an edge with the static box, which should look neat.
		SDL::Tutorial::3DWorld::Actor::GridCube->new(
			position => [ -0.33, 0.01, -0.66 ],
			velocity => $self->dvector( -0.1, 0.1, -0.1 ),
		),

		# Place a typical large crate on the opposite side of the
		# chessboard from the static gridcube.
		SDL::Tutorial::3DWorld::Actor::TextureCube->new(
			size     => 1.3,
			position => [ 3.3, 0.0, 3.35 ],
			material => {
				ambient => [ 0.5, 0.5, 0.5, 1 ],
				texture => $self->sharefile('crate1.jpg'),
			},
		),

		# Place a lollipop near the origin
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ -2, 0, 0 ],
			file     => File::Spec->catfile('model', 'lollipop', 'hflollipop1gr.rwx'),
		),

		# Place two nutcrackers a little further away
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ -2, 0, -2 ],
			file     => File::Spec->catfile('model', 'nutcracker', "sv-nutcracker1.rwx"),
		),
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ -4, 0, -2 ],
			file     => File::Spec->catfile('model', 'nutcracker', "sv-nutcracker7.rwx"),
		),

		# Place a large table (somewhere...)
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ -10, 0, 0 ],
			scale    => [ 0.05, 0.05, 0.05 ],
			file     => File::Spec->catfile('model', 'table', 'table.obj'),
			plain    => 1,
		),

		# Add a material sampler
		SDL::Tutorial::3DWorld::Actor::MaterialSampler->new(
			position => [ 5, 1, 5 ],
			file     => File::Spec->catfile(
				File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
				'example.mtl',
			),
		),

	];

	# Add a grid of toilet plungers
	foreach my $x ( -15 .. -5 ) {
		foreach my $z ( 5 .. 15 ) {
			push @$actors, SDL::Tutorial::3DWorld::Actor::Model->new(
				position => [ $x, 1.6, $z ],
				file     => File::Spec->catfile(
					'model',
					'toilet-plunger001',
					'toilet_plunger001.obj',
				),
			);
		}
	}

	# Add a bounding box viewer to as many objects as support it
	push @$actors, map {
		SDL::Tutorial::3DWorld::Actor::Debug->new( parent => $_ )
	} @$actors;

	# Light the world with a single overhead light
	$self->{lights} = [
		SDL::Tutorial::3DWorld::Light->new(
			X => 360,
			Y => 405,
			Z => -400,
		),
	];

	# Optimisation:
	# If we have a skybox then now part of the scene will ever show
	# the background. As a result, we can clear only the depth buffer
	# and this will result in the color buffer just being drawn over.
	# This removes a fairly large memory clear operation and speeds
	# up frame-initialisation phase of the rendering pipeline.
	if ( $self->{skybox} ) {
		$self->{clear} = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT;
	} else {
		$self->{clear} = GL_DEPTH_BUFFER_BIT;
	}

	return $self;
}

=pod

=head2 camera

The C<camera> method returns the currently active camera for the world.

Provided as a convenience for world objects that need to know where the
camera is (such as the skybox).

=cut

sub camera {
	$_[0]->{camera};
}

=pod

=head2 sdl

The C<sdl> method returns the master L<SDLx::App> object for the world.

=cut

sub sdl {
	$_[0]->{sdl};
}





######################################################################
# Main Methods

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

	# Movement handler
	$self->{sdl}->add_move_handler( sub {
		if ( $self->{benchmark} and $_[2] > 100 ) {
			$_[1]->stop;
			return;
		}
		return unless $_[0];
		$self->move(@_);
	} );

	# Event handler
	$self->{sdl}->add_event_handler( sub {
		$self->event(@_);
	} );

	# This world is now the active world
	local $CURRENT = $self;

	# Enter the main loop
	$self->{sdl}->run;

	return 1;
}

=pod

=head2 current

The C<current> method can be used by any arbitrary world element to get
access to the world while it is running.

=cut

sub current {
	$CURRENT or die "No current world is running";
}





######################################################################
# Internal Methods

sub init {
	my $self = shift;

	# Verify the integrity of the installation. This shouldn't really
	# be necesary but kthakore seems to have problems with partial
	# overwriting his installs and mixing up versions of something.
	# This is an attempt to at least partially defend against them.
	foreach my $child ( sort grep { /3DWorld\// } keys %INC ) {
		$child =~ s/\//::/g;
		$child =~ s/\.pm//g;
		next unless Params::Util::_CLASS($child);
		my $v = $child->VERSION;
		unless ( $v ) {
			die "Corrupt installation detected! No \$VERSION in $child";
		}
		unless ( $v == $VERSION ) {
			die "Corrupt installation detected! Got \$VERSION $v in $child but expected $VERSION";
		}
	}

	# Normally we want fullscreen, but occasionally we might want to
	# disable it because we are on a portrait-orientation monitor
	# or for unobtrusive testing (or it doesn't work on some machine).
	# When showing in a window, drop the size to the window isn't huge.
	my $fullscreen = not grep { $_ eq '--window' } @{$self->{ARGV}};
	unless ( $fullscreen ) {
		$self->{width}  = int( $self->{width}  / 2 );
		$self->{height} = int( $self->{height} / 2 );
	}

	# Are we doing a benchmarking run?
	# If so set the flag and we will abort after 100 seconds.
	$self->{benchmark} = scalar grep { $_ eq '--benchmark' } @{$self->{ARGV}};

	# Create the SDL application object
	$self->{sdl} = SDLx::App->new(
		title         => '3D World',
		width         => $self->{width},
		height        => $self->{height},
		gl            => 1,
		fullscreen    => $fullscreen,
		depth         => 24, # Prevent harsh colour stepping
		double_buffer => 1,  # Reduce flicker during rapid mouselook
		min_t         => 0,  # As many frames as possible
	);

	# Enable face culling to remove drawing of all rear surfaces
	glCullFace( GL_BACK );
	glEnable( GL_CULL_FACE );

	# Use the prettiest shading available to us
	glShadeModel( GL_SMOOTH );

	# Enable the Z buffer (DEPTH BUFFER) so that OpenGL will do all the
	# correct shape culling for us and we don't have to care about it.
	glDepthFunc( GL_LESS );
	glEnable( GL_DEPTH_TEST );

	# How thick are lines
	glLineWidth( 1 );

	# Enable basic anti-aliasing for everything
	# glEnable( GL_BLEND );
	# glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glHint( GL_LINE_SMOOTH_HINT,    GL_NICEST );
	glHint( GL_POINT_SMOOTH_HINT,   GL_NICEST );
	glHint( GL_POLYGON_SMOOTH_HINT, GL_NICEST );
	glHint( GL_GENERATE_MIPMAP_HINT, GL_NICEST );
	# glEnable( GL_LINE_SMOOTH    );
	# glEnable( GL_POINT_SMOOTH   );
	# glEnable( GL_POLYGON_SMOOTH );

	# Lighting and textures are on by default
	glEnable( GL_LIGHTING );
	glEnable( GL_TEXTURE_2D );

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

	# Initialise the actors.
	# Randomise the order once to generate interesting effects.
	foreach my $actor ( @{$self->{actors}} ) {
		$actor->init;
	}

	# Initialise the console
	if ( $self->{console} ) {
		$self->{console}->init;
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
	# glEnable( GL_LIGHTING );
	# glEnable( GL_TEXTURE_2D );

	# Move the camera to the required position.
	# NOTE: For now just translate back so we can see the render.
	$self->{camera}->display;

	# Draw the skybox
	$self->{skybox}->display if $self->{skybox};

	# Draw the landscape in the scene
	$self->{landscape}->display;

	# Light the scene
	foreach my $light ( @{$self->{lights}} ) {
		$light->display;
	}

	# Draw each of the actors into the scene.
	# We should draw the models for most distance to least distant
	# to ensure that transparent objects will blend over the top
	# of things behind them correctly.
	foreach my $actor ( $self->display_actors ) {
		# Draw each actor in their own stack context so that
		# their transform operations do not effect anything else.
		glPushMatrix();
		$actor->display;
		glPopMatrix();
	}

	# Draw the console last, on top of everything else
	if ( $self->{console} and not $self->{hide_console} ) {
		$self->{console}->display;
	}

	return 1;
}

sub move {
	my $self = shift;

	# Move each of the actors in the scene
	foreach my $actor ( @{$self->{actors}} ) {
		next unless $actor->{velocity};
		$actor->move(@_);
	}

	# Move the camera last, since it is more likely that the position
	# of the camera will be limited by where the actors are than the
	# actors being limited by where the camera is.
	$self->{camera}->move(@_);
}

sub event {
	my $self  = shift;
	my $event = shift;
	my $type  = $event->type;

	if ( $type == SDL_KEYDOWN ) {
		my $key = $event->key_sym;

		# Quit the world
		if ( $key == SDLK_ESCAPE ) {
			$self->{sdl}->stop;
			return 1;
		}

		# Toggle visibility of debugging actors
		if ( $key == SDLK_F1 ) {
			$self->{hide_debug} = $self->{hide_debug} ? 0 : 1;
			foreach my $actor ( @{$self->{actors}} ) {
				next unless $actor->isa('SDL::Tutorial::3DWorld::Actor::Debug');
				$actor->{hidden} = $self->{hide_debug};
			}
			return 1;
		}

		# Toggle visibility for unrealistically-expensive actors
		if ( $key == SDLK_F2 ) {
			$self->{hide_expensive} = $self->{hide_expensive} ? 0 : 1;
			foreach my $actor ( @{$self->{actors}} ) {
				if ( $actor->isa('SDL::Tutorial::3DWorld::Actor::MaterialSampler') ) {
					$actor->{hidden} = $self->{hide_expensive};
				}
				if ( $actor->isa('SDL::Tutorial::3DWorld::Actor::Teapot') ) {
					$actor->{hidden} = $self->{hide_expensive};
				}
			}
			return 1;
		}

		# Toggle visibility of the console (i.e. the FPS display)
		if ( $key == SDLK_F3 ) {
			$self->{hide_console} = $self->{hide_console} ? 0 : 1;
			return 1;
		}

	} elsif ( $type == SDL_MOUSEBUTTONDOWN ) {
		# Make the scroll wheel move the selection box towards
		# and away from the camera.
		my $button = $event->button_button;
		if ( $button == SDL_BUTTON_WHEELUP ) {
			# Move away from the camera
			$self->{selector}->{distance} += 0.5;
			return 1;
		}
		if ( $button == SDL_BUTTON_WHEELDOWN ) {
			# Move towards the camera, stopping
			# at some suitable minimum distance.
			$self->{selector}->{distance} -= 0.5;
			if ( $self->{selector}->{distance} < 2 ) {
				$self->{selector}->{distance} = 2;
			}
			return 1;
		}
		if ( $button == SDL_BUTTON_LEFT ) {
			# Place a new texture box at the selector location
			my $selector = $self->{selector}->{position};
			my $cube     = SDL::Tutorial::3DWorld::Actor::TextureCube->new(
				position => [
					$selector->[0] + 0.5,
					$selector->[1],
					$selector->[2] + 0.5,
				],
				material => {
					ambient => [ 0.5, 0.5, 0.5, 1 ],
					texture => $self->sharefile('crate1.jpg'),
				},
			);
			$cube->init;
			push @{$self->{actors}}, $cube;

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
# NOTE: If you are using a full six sided sky box then you don't need to clear
# the color buffer because you'll always draw over the top of every pixel.
# Clearing only the depth buffer should make your rendering faster.
sub clear {
	glClear( $_[0]->{clear} );
}

# This is a convenience method.
# Pass through to the version provided by the main SDL app.
sub sync {
	$_[0]->{sdl}->sync;
}

# A simple actor ordering method based on naive distance from the
# camera as measured from the centre position() of the object.
sub display_actors {
	my $self   = shift;
	my $camera = $self->{camera};

	# Apply optimisation strategies to remove things we don't need to
	# draw. At the same time split solid and transparent objects apart
	# as we will use different rendering optimisations for each type.
	my @solid = ();
	my @blend = ();
	foreach my $actor ( @{$self->{actors}} ) {
		# Don't render actors that are intentionall hidden
		next if $actor->{hidden};

		# Don't render actors that aren't in our field of view
		my @box     = $actor->box;
		my $visible = @box
			? $camera->visible_box(@box)
			: $camera->visible_point(@{$actor->position});
		next unless $visible;

		# Render solid objects first to avoid some n-body related
		# costs when distance sorting to find actor display order.
		if ( $actor->{blending} ) {
			push @blend, $actor;
		} else {
			push @solid, $actor;
		}
	}

	# Sort the solid objects from nearest to farthest. If a large
	# model is close to the camera then any object behind it only
	# needs to be depth-testing and all the work to colour, texture
	# and light the object can be skipped by OpenGL.
	# NOTE: This is disabled for the time being as I suspect the
	# cost of the geometry math and sorting in Perl is larger than
	# the cost of just brute forcing it in modern graphics hardware.
	# @solid = reverse map { $solid[$_] } $self->camera->distance_isort(
		# map { $_->{position} } @solid
	# );

	# Sort the blending objects from farthest to nearest. A transparent
	# object needs to have everything behind it drawn so that it can
	# do the alpha transparency over the top of it,
	@blend = map { $blend[$_] } $camera->distance_isort(
		map { $_->{position} } @blend
	);

	return ( @solid, @blend );
}

sub dvector {
	my $dt = $_[0]->{dt};
	return [
		$_[1] * $dt,
		$_[2] * $dt,
		$_[3] * $dt,
	];
}

sub dscalar {
	$_[0]->{dt} * $_[1];
}

sub sharedir {
	my $self = shift;
	File::Spec->rel2abs(
		File::Spec->catdir(
			File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
			@_,
		),
	);
}

sub sharefile {
	my $self = shift;
	File::Spec->rel2abs(
		File::Spec->catfile(
			File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
			@_,
		),
	);
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
