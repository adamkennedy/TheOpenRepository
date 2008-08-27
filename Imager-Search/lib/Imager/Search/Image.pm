package Imager::Search::Image;

# Generic Interface for a target image

use strict;
use Params::Util qw{ _POSINT _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( _POSINT($self->height) ) {
		Carp::croak("Missing or invalid height param");
	}
	unless ( _POSINT($self->width) ) {
		Carp::croak("Missing or invalid width param");
	}
	unless ( defined $self->string ) {
		Carp::croak("Missing or invalid string param");
	}
	if ( $self->{class} ) {
		if ( $self->{class} eq $class ) {
			delete $self->{class};
		} else {
			Carp::croak("Image class mismatch");
		}
	}

	return $self;
}

sub driver {
	$_[0]->{driver};
}

sub height {
	$_[0]->{height};
}

sub width {
	$_[0]->{width};
}

sub string {
	$_[0]->{string};
}

sub transformed {
	my $self = shift;
	die "The transformed_string method must be implemented by a child class";
}





#####################################################################
# Search Methods

=pod

=head2 find

The C<find> method compiles the search and target images in memory, and
executes a single search, returning the position of the first match as a
L<Imager::Match::Occurance> object.

=cut

sub find {
	my $self = shift;

	# Get the search expression
        my $pattern = _INSTANCE(shift, 'Imager::Search::Pattern')
	or die "Did not pass a Pattern object to find";
	my $regexp  = $pattern->regexp( $self );

	# Run the search
	my @match = ();
	my $big   = $self->string;
	my $bpp   = $self->driver->bytes_per_pixel;
	while ( scalar $$big =~ /$regexp/gs ) {
		my $p = $-[0];
		push @match, Imager::Search::Match->from_position($self, $pattern, $p / $bpp);
		pos $big = $p + 1;
	}
	return @match;
}

=pod

=head2 find_first

The C<find_first> compiles the search and target images in memory, and
executes a single search, returning the position of the first match as a
L<Imager::Match::Occurance> object.

=cut

sub find_first {
	my $self  = shift;

	# Load the strings.
	# Do it by reference entirely for performance reasons.
	# This avoids copying some potentially very large string.
	my $small = '';
	my $big   = '';
	$self->_small_string( \$small );
	$self->_big_string( \$big );

	# Run the search
	my $bpp = $self->bytes_per_pixel;
	while ( scalar $big =~ /$small/gs ) {
		my $p = $-[0];
		return Imager::Search::Match->from_position($self, $p / $bpp);
	}
	return undef;
}

1;
