package SDL::Tutorial::3DWorld::Actor::SpriteOct;

use 5.008;
use strict;
use warnings;
use OpenGL::List                     ();
use SDL::Tutorial::3DWorld           ();
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Texture  ();
use SDL::Tutorial::3DWorld::Material ();
use SDL::Tutorial::3DWorld::Actor    ();

our $VERSION = '0.32';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(
		blending => 1,
		@_,
	);

	# Convert the texture to a full material
	$self->{material} = [
		map {
			SDL::Tutorial::3DWorld::Material->new(
				ambient => [ 1, 1, 1, 0.5 ],
				diffuse => [ 1, 1, 1, 0.5 ],
				texture => SDL::Tutorial::3DWorld::Texture->new(
					file       => $_,
					tile       => 0,
					mag_filter => OpenGL::GL_NEAREST,
				),
			),
		} ( @{$self->{texture}} )
	];

	return $self;
}

sub init {
	my $self = shift;

	# Compile the common drawing code
	$self->{draw} = OpenGL::List::glpList {
		$self->compile;
	};

	return 1;
}

sub display {
	my $self  = shift;
	my $angle = -SDL::Tutorial::3DWorld->current->camera->{angle};
	$self->SUPER::display(@_);

	# Rotate towards the camera
	OpenGL::glRotatef( $angle, 0, 1, 0 );

	# Switch to the sprite
	$self->{material}->[0]->display;

	# Draw the sprite quad.
	OpenGL::glCallList( $self->{draw} );
}

sub compile {
	my $self = shift;

	# Draw the sprite quad.
	# The texture seems to wrap a little unless we use the 0.01 here.
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glBegin( OpenGL::GL_QUADS );
	OpenGL::glTexCoord2f( 0, 0 ); OpenGL::glVertex3f( -0.5,  1,  0 ); # Top Left
	OpenGL::glTexCoord2f( 0, 1 ); OpenGL::glVertex3f( -0.5,  0,  0 ); # Bottom Left
	OpenGL::glTexCoord2f( 1, 1 ); OpenGL::glVertex3f(  0.5,  0,  0 ); # Bottom Right
	OpenGL::glTexCoord2f( 1, 0 ); OpenGL::glVertex3f(  0.5,  1,  0 ); # Top Right
	OpenGL::glEnd();
	OpenGL::glEnable( OpenGL::GL_LIGHTING );

	return 1;
}

1;
