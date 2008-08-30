package Imager::Search::Driver::HTML8;

# Basic search driver implemented in terms of 8-bit
# HTML-style strings ( #003399 )

use 5.005;
use strict;
use Imager::Search::Match ();
use base 'Imager::Search::Driver';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}





#####################################################################
# Imager::Search::Driver Methods

sub match_object {
	my $self      = shift;
	my $image     = shift;
	my $pattern   = shift;
	my $character = shift;

	# Derive the pixel position from the character position
	my $pixel   = $self->match_pixel( $character );

	# If the pixel position isn't an integer we matched
	# at a position that is not a pixel boundary, and thus
	# this match is a false positive. Shortcut to fail.
	unless ( $pixel == int($pixel) ) {
		return; # undef or null list
	}

	# Calculate the basic geometry of the match
	my $top    = int( $pixel / $image->width );
	my $left   = $pixel % $image->width;

	# If the match overlaps the newline boundary or falls off the bottom
	# of the image, this is also a false positive. Shortcut to fail.
	if ( $left > $image->width - $pattern->width ) {
		return; # undef or null list
	}
	if ( $top > $image->height - $pattern->height ) {
		return; # undef or null list
	}

	# This is a legitimate match.
	# Convert to a match object and return.
	return Imager::Search::Match->new(
		top    => $top,
		left   => $left,
		height => $pattern->height,
		width  => $pattern->width,
	);
}

sub match_pixel {
	$_[1] / 7;
}

sub pattern_newline {
	__transform_pattern_newline($_[1]);
}

sub transform_pattern_newline {
	return \&__transform_pattern_newline;
}

sub transform_pattern_line {
	return \&__transform_pattern_line;
}

sub transform_image_line {
	return \&__transform_image_line;
}





#####################################################################
# Transform Functions

sub __transform_pattern_line ($) {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
}

sub __transform_image_line ($) {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
};

sub __transform_pattern_newline ($) {
	return '.{' . ($_[0] * 7) . '}';
}





#####################################################################
# Imager::Search::Driver Methods

sub image_string {
	my $self       = shift;
	my $scalar_ref = shift;
	my $image      = shift;
	my $height     = $image->getheight;
	foreach my $row ( 0 .. $height - 1 ) {
		# Get the string for the row
		$$scalar_ref .= join('',
			map { sprintf("#%02X%02X%02X", ($_->rgba)[0..2]) }
			$image->getscanline( y => $row )
		);
	}

	# Return the scalar reference as a convenience
	return $scalar_ref;
}

1;

__END__

=pod

=head1 NAME

Imager::Search::Driver::HTML8 - Simple Imager::Search::Driver using #RRBBGG strings

=head1 DESCRIPTION

B<Imager::Search::Driver::HTML8> is a simple default driver for L<Imager::Search>.

It uses a HTML color string like #0033FF for each pixel, providing both a
simple text expression of the colour, as well as a hash pixel separator.

Search patterns are compressed, so that a horizontal stream of identical
pixels are represented as a single match group.

Color-wise, an HTML8 search is considered to be 3-channel 8-bit.

Support for 1-bit alpha transparency (ala "transparent gifs") is not
currently supported but is likely be implemented in the future.

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
