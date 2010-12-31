package SDL::Tutorial::3DWorld::Frustrum;

# Takes the same parameters as gluPerspective

use 5.008;
use strict;
use warnings;

our $VERSION = '0.28';

use constant D2R => CORE::atan2(1,1) / 45;

sub new {
	my $class  = shift;
	my $self   = bless {
		aspect  => $_[1],
		fovy    => $_[0],
		fovx    => $_[0] * $_[1],
		znear   => $_[2],
		zfar    => $_[3],
		zsphere => ($_[2] + $_[3]) / 2,
	}, $class;

	# Find the radius of the sphere
	### NOTE: Do this right and don't fudge
	$self->{rsphere} = 500;

	return $self;
}

# Calculate the camera sphere for doing fast sphere-sphere culling
sub sphere {
	my $self      = shift;
	my $zsphere   = $self->{zsphere};
	my $camera    = shift;
	my $direction = $camera->{direction};
	return [
		$direction->[0] * $zsphere,
		$direction->[1] * $zsphere,
		$direction->[2] * $zsphere,
		$self->{rsphere},
	];
}

1;
