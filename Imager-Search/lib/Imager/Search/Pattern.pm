package Imager::Search::Pattern;

use strict;
use Params::Util qw{ _INSTANCE };
use Imager       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}

use Object::Tiny qw{
	name
	driver
	image
	height
	width
	lines
};





#####################################################################
# Constructors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _INSTANCE($self->driver, 'Imager::Search::Driver') ) {
		Carp::croak("Did not provide a valid driver");
	}
	if ( defined $self->image ) {
		unless( _INSTANCE($self->image, 'Imager') ) {
			Carp::croak("Did not provide a valid image");
		}
		$self->{height} = $self->image->getheight;
		$self->{width}  = $self->image->getwidth;
		unless ( _POSINT($self->height) ) {
			Carp::croak("Invalid or missing image height");
		}
		unless ( _POSINT($self->width) ) {
			Carp::croak("Invalid or missing image width");
		}
		$self->{lines} = $self->driver->
	}

	return $self;
}

1;
