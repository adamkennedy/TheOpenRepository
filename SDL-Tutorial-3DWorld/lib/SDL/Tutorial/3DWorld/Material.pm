package SDL::Tutorial::3DWorld::Material;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL ();

our $VERSION = '0.21';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless {
		# Default elements
		ambient   => [ 0.2, 0.2, 0.2, 1.0 ],
		diffuse   => [ 0.8, 0.8, 0.8, 1.0 ],
		specular  => [ 0.0, 0.0, 0.0, 0.0 ],
		shininess => 8,
		@_,
	}, $class;
	return $self;
}

sub ambient {
	$_[0]->{ambient};
}

sub diffuse {
	$_[0]->{diffuse};
}

sub specular {
	$_[0]->{specular};
}

sub shininess {
	$_[0]->{shininess};
}

sub illumination {
	$_[0]->{illumination};
}





######################################################################
# Engine Methods

sub init {
	return 1;
}

# Apply the material to the current OpenGL context
sub display {
	my $self = shift;

	# Apply the material properties
	OpenGL::glMaterialfv_p(
		OpenGL::GL_FRONT_AND_BACK,
		OpenGL::GL_AMBIENT,
		@{ $self->{ambient} },
	);
	OpenGL::glMaterialfv_p(
		OpenGL::GL_FRONT_AND_BACK,
		OpenGL::GL_DIFFUSE,
		@{ $self->{diffuse} },
	);
	OpenGL::glMaterialfv_p(
		OpenGL::GL_FRONT_AND_BACK,
		OpenGL::GL_SPECULAR,
		@{ $self->{specular} },
	);
	OpenGL::glMaterialf(
		OpenGL::GL_FRONT_AND_BACK,
		OpenGL::GL_SHININESS,
		$self->{shininess},
	);

	return 1;
}

1;
