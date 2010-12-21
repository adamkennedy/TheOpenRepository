package SDL::Tutorial::3DWorld::Material;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.21';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
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

sub display {
	return 1;
}

1;
