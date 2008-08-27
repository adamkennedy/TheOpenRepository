package Imager::Search::Match;

use 5.005;
use strict;
use Carp         ();
use Params::Util qw{ _POSINT _NONNEGINT _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

use Object::Tiny qw{
	top
	bottom
	left
	right
	height
	width
	center_x
	center_y
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Checking params
	

	return $self;
}

sub from_position {
	my $class    = shift;
	my $image    = _INSTANCE(shift, 'Imager::Search::Image')
		or Carp::croak("Failed to provide Imager::Search::Image param");
	my $pattern  = _INSTANCE(shift, 'Imager::Search::Pattern')
		or Carp::croak("Failed to provide Imager::Search::Pattern param");
	my $position = _NONNEGINT(shift);
	unless ( defined $position ) {
		Carp::croak("Failed to provide position");
	}

	# Determine the position elements
	my $width    = $pattern->width;
	my $height   = $pattern->height;
	my $top      = int($position / $image->width);
	my $left     = $position % $image->width;
	my $bottom   = $top + $height - 1;
	my $right    = $left + $width - 1;
	my $center_x = int(($left + $right)  / 2);
	my $center_y = int(($top  + $bottom) / 2);

	# Create the object
	return $class->new(
		left     => $left,
		right    => $right,
		top      => $top,
		bottom   => $bottom,
		height   => $height,
		width    => $width,
		center_x => $center_x,
		center_y => $center_y,
	);
}

1;

__END__

=pod

=head1 NAME

Imager::Search::Match - Object describing a successful Imager::Search match

=head1 DESCRIPTION

B<Imager::Search::Match> is a convenience class that represents the complete
geometry of a successful L<Imager::Search> match.

It is returned by the various search methods in L<Imager::Search>.

B<Imager::Search::Match> objects are self-contained and anonymous, they do
not retain a connection to the original search context.

=head1 METHODS

=head2 top

The C<top> accessor returns the integer value of the inclusive vertical top
of the search match.

=head2 bottom

The C<bottom> accessor returns the integer value of the inclusive vertical
bottom of the search match.

=head1 left

The C<left> accessor returns the integer value of the inclusive horizontal
left of  the search match.

=head1 right

The C<right> accessor returns the integer value of the inclusive horizontal
right of the search match.

=head1 height

The C<height> accessor returns the integer value of the vertical height of
the matched area.

=head1 width

The C<width> accessor returns the integer value of the horizontal width of
the matched area.

=head1 centre_x

The C<centre_x> accessor returns the integer value of the horizontal centre
pixel of the matched image. If the matched image has an even number of
horizonal pixels, the value will be rounded to the left.

=head1 centre_y

The C<centre_y> accessor returns the integer value of the vertical centre
pixel of the matched image. If the matched image has an even number of
vertical pixels, the value will be rounded to the top.

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
