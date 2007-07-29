package Imager::Search::RRGGBB;

# Basic search engine implemented in terms of web colours ( #003399 )

use strict;
use base 'Imager::Search';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}





#####################################################################
# API Methods

sub small_transform {
	return \&__small_transform;
}

sub __small_transform {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
}

sub big_transform {
	return \&__big_transform;
}

sub __big_transform {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
};

sub newline_transform {
	return \&__newline_transform;
}

sub __newline_transform {
	my $chars = $_[0] * 7;
	return ".{$chars}";
}

sub bytes_per_pixel {
	return 7;
}

1;

__END__

=pod

=head1 NAME

Imager::Search::RRGGBB - Simple Imager::Search driver using #RRBBGG strings

=head1 DESCRIPTION

B<Imager::Search::RRGGBB> is a simple default driver for L<Imager::Search>.

It uses a HTML color in the #RRGGBB style for each pixel, providing both a
simple text expression of the colour, as well as a hash pixel separator.

Search expressions are auto-condensed, so that a horizontal stream of
identical pixels are represented as a single match group (reducing the size
of the search expression).

Color-wise, an RRGGBB search is considered to be 3-channel 16-bit. Support
for transparency is not currently supported but may be supported in the
future for the transparent regions in the search image (but not the target
image).

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
