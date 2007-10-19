package Imager::Search::Driver::HTML8;

# Basic search driver implemented in terms of 8-bit
# HTML-style strings ( #003399 )

use 5.005;
use strict;
use base 'Imager::Search::Driver';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}





#####################################################################
# API Methods

sub bytes_per_pixel {
	return 7;
}

sub pattern_transform {
	return \&__pattern_transform;
}

sub image_transform {
	return \&__image_transform;
}

sub newline_transform {
	return \&__newline_transform;
}





#####################################################################
# Transform Functions

sub __pattern_transform ($) {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
}

sub __image_transform ($) {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
};

sub __newline_transform ($) {
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
		$$scalar_ref = join('',
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
