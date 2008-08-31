package Imager::Search::Image::File;

use strict;
use base 'Imager::Search::Image';
use Imager ();
use Params::Util '_IDENTIFIER', '_INSTANCE', '_DRIVER';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	if ( _IDENTIFIER($self->driver) ) {
		$self->{driver} = "Imager::Search::Driver::" . $self->driver;
	}
	if ( _DRIVER($self->driver, 'Imager::Search::Driver') ) {
		$self->{driver} = $self->driver->new;
	}
	unless ( _INSTANCE($self->driver, 'Imager::Search::Driver') ) {
		Carp::croak("Did not provide a valid driver");
	}
	if ( defined $self->file and ! defined $self->image ) {
		# Load the image from a file
		$self->{image} = Imager->new;
		$self->{image}->read( file => $self->file );
	}
	if ( defined $self->image ) {
		unless( _INSTANCE($self->image, 'Imager') ) {
			Carp::croak("Did not provide a valid image");
		}
		$self->{height} = $self->image->getheight;
		$self->{width}  = $self->image->getwidth;
		my $string = '';
		$self->{string} = $self->driver->image_string(\$string, $self->image);
	}

	return $class->SUPER::new( %$self );
}

sub file {
	$_[0]->{file};
}

sub image {
	$_[0]->{image};
}

1;
