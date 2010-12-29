package SDL::Tutorial::3DWorld::Actor::GridSelect;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld         ();
use SDL::Tutorial::3DWorld::OpenGL ();
use SDL::Tutorial::3DWorld::Actor  ();
use OpenGL::List                   ();

# Use proper POSIX math rather than playing games with Perl's int()
use POSIX ();

our $VERSION = '0.24';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $self = shift->SUPER::new(@_);

	# Gridcubes need blending
	$self->{blending} = 1;

	# The select box starts 2.5 metres in front of the camera
	$self->{distance} = 2.5;

	# The select box is a 1 metre cube
	# $self->{box} = [ 0, 0, 0, 1, 1, 1 ];

	return $self;
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;
	$self->SUPER::init(@_);

	# Compile the point and cube lists
	$self->{list} = OpenGL::List::glpList {
		$self->compile;
	};

	return 1;
}

sub move {
	my $self      = shift;
	my $camera    = SDL::Tutorial::3DWorld::Camera->current;
	my $distance  = $self->{distance};
	my $direction = $camera->{direction};
	$self->{position} = [
		POSIX::floor( $self->{X} + $distance * $direction->[0] ),
		POSIX::floor( $self->{Y} + $distance * $direction->[1] ),
		POSIX::floor( $self->{Z} + $distance * $direction->[2] ),
	];
	return 1;
}

sub display {
	my $self = shift;

	# Translate to the correct location
	$self->SUPER::display(@_);

	# Draw the 1m cube at the location
	OpenGL::glCallList( $self->{list} );
}

# The compilable section of the grid cube display logic
sub compile {
	# The cube is plain opaque full-bright white and ignores lighting
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );

	# Enable line smoothing
	OpenGL::glBlendFunc( OpenGL::GL_SRC_ALPHA, OpenGL::GL_ONE_MINUS_SRC_ALPHA );
	OpenGL::glEnable( OpenGL::GL_BLEND );
	OpenGL::glEnable( OpenGL::GL_LINE_SMOOTH );

	# Draw all the lines in the cube
	OpenGL::glColor4f( 1.0, 1.0, 1.0, 1.0 );
	OpenGL::glLineWidth(2);
	OpenGL::glBegin( OpenGL::GL_LINES );
	OpenGL::glVertex3f( 0, 0, 0 ); OpenGL::glVertex3f( 1, 0, 0 );
	OpenGL::glVertex3f( 0, 0, 0 ); OpenGL::glVertex3f( 0, 1, 0 );
	OpenGL::glVertex3f( 0, 0, 0 ); OpenGL::glVertex3f( 0, 0, 1 );
	OpenGL::glVertex3f( 1, 0, 0 ); OpenGL::glVertex3f( 1, 1, 0 );
	OpenGL::glVertex3f( 1, 0, 0 ); OpenGL::glVertex3f( 1, 0, 1 );
	OpenGL::glVertex3f( 0, 1, 0 ); OpenGL::glVertex3f( 1, 1, 0 );
	OpenGL::glVertex3f( 0, 1, 0 ); OpenGL::glVertex3f( 0, 1, 1 );
	OpenGL::glVertex3f( 0, 0, 1 ); OpenGL::glVertex3f( 1, 0, 1 );
	OpenGL::glVertex3f( 0, 0, 1 ); OpenGL::glVertex3f( 0, 1, 1 );
	OpenGL::glVertex3f( 1, 1, 0 ); OpenGL::glVertex3f( 1, 1, 1 );
	OpenGL::glVertex3f( 1, 0, 1 ); OpenGL::glVertex3f( 1, 1, 1 );
	OpenGL::glVertex3f( 0, 1, 1 ); OpenGL::glVertex3f( 1, 1, 1 );
	OpenGL::glEnd();

	# Disable line smoothing
	OpenGL::glDisable( OpenGL::GL_LINE_SMOOTH );
	OpenGL::glDisable( OpenGL::GL_BLEND );

	# Restore lighting
	OpenGL::glEnable( OpenGL::GL_LIGHTING );
}

1;
