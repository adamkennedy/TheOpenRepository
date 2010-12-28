package SDL::Tutorial::3DWorld::Actor::Box;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::Actor  ();
use SDL::Tutorial::3DWorld::OpenGL ();
use OpenGL::List                   ();

our $VERSION = '0.22';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Do we have a parent?
	unless ( $self->{parent} ) {
		die "Did not provide a parent actor";
	}

	# Lock our position to that of our parent
	$self->{position} = $self->{parent}->{position};

	# We blend, but don't move
	$self->{blending} = 0;

	return $self;
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;

	# Generate the cube display list
	$self->{list} = OpenGL::List::glpList {
		$self->compile;
	};

	return 1;
}

sub box {
	$_[0]->{parent}->box;
}

sub display {
	my $self = shift;

	# Get the full bounding box of our parent
	my @box = $self->{parent}->box or return;

	# Translate to the negative corner
	OpenGL::glTranslatef( @box[0..2] );

	# Scale so that the resulting 1 metre cube becomes the right size
	OpenGL::glScalef(
		$box[3] - $box[0],
		$box[4] - $box[1],
		$box[5] - $box[2],
	);

	# Call the display list to render the cube
	OpenGL::glCallList( $self->{list} );
}

sub compile {
	my $self = shift;

	# The cube is plain opaque full-bright white and ignores lighting
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );

	# Enable line smoothing
	#OpenGL::glBlendFunc( OpenGL::GL_SRC_ALPHA, OpenGL::GL_ONE_MINUS_SRC_ALPHA );
	OpenGL::glDisable( OpenGL::GL_BLEND );
	OpenGL::glDisable( OpenGL::GL_LINE_SMOOTH );

	# Draw all the lines in the cube
	OpenGL::glColor4f( 0.5, 1, 0.50, 1.0 );
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

	# Revert the light disable
	OpenGL::glEnable( OpenGL::GL_LIGHTING );
}

1;
