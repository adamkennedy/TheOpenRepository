package Imager::Search;

=pod

=head1 NAME

Imager::Search - Locate images inside other images

=head1 DESCRIPTION

To be completed.

=cut

use 5.005;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

use Imager::Search::Pattern ();
use Imager::Search::Driver  ();
use Imager::Search::Match   ();





#####################################################################
# Main Methods

=pod

=head2 find

The C<find> method compiles the search and target images in memory, and
executes a single search, returning the position of the first match as a
L<Imager::Match::Occurance> object.

=cut

sub find {
	my $self  = shift;

	# Load the strings.
	# Do it by reference entirely for performance reasons.
	# This avoids copying some potentially very large string.
	my $small = '';
	my $big   = '';
	$self->_small_string( \$small );
	$self->_big_string( \$big );

	# Run the search
	my @match = ();
	my $bpp   = $self->bytes_per_pixel;
	while ( scalar $big =~ /$small/gs ) {
		my $p = $-[0];
		push @match, Imager::Match::Occurance->from_position($self, $p / $bpp);
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
		return Imager::Match::Occurance->from_position($self, $p / $bpp);
	}
	return undef;
}

1;

=pod

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
