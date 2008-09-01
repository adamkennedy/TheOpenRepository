package Imager::Search::Driver::HTML24;

# Basic search driver implemented in terms of 8-bit
# HTML-style strings ( #003399 )

use 5.006;
use strict;
use Imager::Search::Match ();
use base 'Imager::Search::Driver';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}





#####################################################################
# Imager::Search::Driver Methods

sub match_object {
	my $self      = shift;
	my $image     = shift;
	my $pattern   = shift;
	my $character = shift;

	# Derive the pixel position from the character position
	my $pixel = $character / 7;

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

sub transform_pattern_newline {
	return \&__transform_pattern_newline;
}

sub transform_pattern_line {
	return \&__transform_pattern_line;
}

sub pattern_regexp {
	my $self    = shift;
	my $pattern = shift;
	my $width   = shift;

	# Assemble the regular expression
	my $pixels  = $width - $pattern->width;
	my $newline = '.{' . ($pixels * 7) . '}';
	my $lines   = $pattern->lines;
	my $string  = join( $newline, @$lines );

	return qr/$string/si;
}

sub pattern_newline {
	my $self = shift;
	
	__transform_pattern_newline($_[1]);
}

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





#####################################################################
# Transform Functions

sub __transform_pattern_line ($) {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
}

sub __transform_pattern_newline ($) {
	return '.{' . ($_[0] * 7) . '}';
}

1;

__END__

=pod

=head1 NAME

Imager::Search::Driver::HTML24 - Simple driver using HTML #RRBBGG strings

=head1 DESCRIPTION

B<Imager::Search::Driver::HTML24> is a simple reference driver for
L<Imager::Search>.

It uses a HTML color string like #0033FF for each pixel, providing both a
simple text expression of the colour, as well as a hash pixel separator.

Search patterns are compressed, so that a horizontal stream of identical
pixels are represented as a single match group.

Color-wise, an HTML24 search is considered to be 3-channel 8-bit.

=head1 SUPPORT

See the SUPPORT section of the main L<Imager::Search> module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
