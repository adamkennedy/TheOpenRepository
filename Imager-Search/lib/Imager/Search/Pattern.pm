package Imager::Search::Pattern;

=pod

=head1 NAME

Imager::Search::Pattern - Search object for an image

=head1 SYNOPSIS

  my $pattern = Imager::Search::Pattern->new(
          driver => 'Imager::Search::Driver::HTML8',
          image  => $Imager,
  );
  
  my $regexp = $pattern->regexp;

=head1 DESCRIPTION

B<Imager::Search::Pattern> takes an L<Imager> object, and converts it
into a partially-compiled regular expression.

This partial regexp can then be quickly turned into the final L<Regexp>
once the widget of the target image is known, as well as being able to
be cached.

This allows a single B<Imager::Search::Pattern> object to be quickly
applied to many different sizes of target images.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp         ();
use IO::File     ();
use Params::Util qw{ _STRING _IDENTIFIER _POSINT _ARRAY _INSTANCE _DRIVER };
use Imager       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

use Object::Tiny qw{
	name
	driver
	cache
	file
	image
	height
	width
	lines
};





#####################################################################
# Constructors

=pod

=head2 new

  $pattern = Imager::Search::Pattern->new(
      driver => 'Imager::Search::Driver::HTML8',
      file   => 'search/image.gif',
      cache  => 1,
  );

=cut

sub new {
	my $self = shift->SUPER::new(@_);

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
		$self->{lines}  = $self->driver->pattern_lines($self->image);
	}
	unless ( _POSINT($self->height) ) {
		Carp::croak("Invalid or missing image height");
	}
	unless ( _POSINT($self->width) ) {
		Carp::croak("Invalid or missing image width");
	}
	unless ( _ARRAY($self->lines) ) {
		Carp::croak("Did not provide an ARRAY of line patterns");
	}

	# Normalise caching behaviour
	$self->{cache} = !! $self->cache;
	if ( $self->cache ) {
		$self->{regexp} = {};
	}

	return $self;
}

sub write {
	my $self = shift;
	my $io   = undef;
	if ( _INSTANCE($_[0], 'IO::Handle') ) {
		$io = $_[0];
	} elsif ( _STRING($_[0]) ) {
		$io = IO::File->new( $_[0], 'w' );
		unless ( _INSTANCE($io, 'IO::File') ) {
			Carp::croak("Failed to open $_[0] to write");
		}
	} else {
		Carp::croak("Did not provide a file or handle to write");
	}

	# The first line is the class of this object
	$io->print( "class: " . ref($self) . "\n" );

	# Next, a series of key: value pairs of the main properties
	foreach my $key ( qw{ driver width height } ) {
		$io->print( $key . ': ' . $self->$key() . "\n" );
	}

	# Ending with a blank newline to indicate the end of the headers
	$io->print("\n");

	# And now we print all of the pattern lines
	my $lines = $self->lines;
	foreach ( 0 .. $#$lines ) {
		$io->print( $lines->[0] . "\n" );
	}

	# Return without closing.
	# Any file we opened will auto-close,
	# and anyone passing a handle should close it themselves.
	return 1;
}





#####################################################################
# Main Methods

sub regexp {
	my $self = shift;

	# Get the width param
	my $width = undef;
	if ( _INSTANCE($_[0], 'Imager') ) {
		$width = $_[0]->getwidth;
	} elsif ( _INSTANCE($_[0], 'Imager::Search::Image') ) {
		$width = $_[0]->width;
	} elsif ( _POSINT($_[0]) ) {
		$width = $_[0];
	} else {
		Carp::croak("Did not provide a width to Imager::Search::Pattern::regexp");
	}

	# Return the cached version if possible
	if ( $self->cache and $self->{regexp}->{$width} ) {
		return $self->{regexp}->{$width};
	}

	# Get the newline pattern
	my $newline_pixels   = $width - $self->width;
	my $newline_function = $self->driver->newline_transform;
	my $newline_regexp   = &$newline_function( $newline_pixels );

	# Merge into the final string
	my $string = '';
	my $lines  = $self->lines;
	foreach my $i ( 0 .. $#$lines ) {
		$string .= $newline_regexp if $string;
		$string .= $lines->[$i];
	}

	# Cache the regexp if needed
	my $regexp = qr/$string/si;
	if ( $self->cache ) {
		$self->{regexp}->{$width} = $regexp;
	}

	return $regexp;
}

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
