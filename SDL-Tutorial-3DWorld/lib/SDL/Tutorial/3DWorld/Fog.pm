package SDL::Tutorial::3DWorld::Fog;

# A small convenience encapsulation for basic OpenGL fog

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL ();

our $VERSION = '0.32';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( defined $self->{mode} ) {
		$self->{mode} = OpenGL::GL_LINEAR;
	}
	unless ( defined $self->{start} ) {
		die "Did not provide a start param";
	}
	unless ( defined $self->{end} ) {
		die "Did not provide an end param";
	}
	unless ( defined $self->{color} ) {
		die "Did not provide a colour param";
	}

	return $self;
}

sub display {
	my $self = shift;

	# Apply the fog settings
	OpenGL::glFogfv_p( OpenGL::GL_FOG_COLOR, @{$self->{color}} );
	OpenGL::glFogi(    OpenGL::GL_FOG_MODE,  $self->{mode}     );
	OpenGL::glFogf(    OpenGL::GL_FOG_START, $self->{start}    );
	OpenGL::glFogf(    OpenGL::GL_FOG_END,   $self->{end}      );
	OpenGL::glEnable(  OpenGL::GL_FOG );

	return 1;
}

1;
