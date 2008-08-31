package Imager::Search::Driver;

=pod

=head1 NAME

Imager::Search::Driver - Abstract imlementation of a Imager::Search driver

=head1 SYNOPSIS

  # Create the search
  my $search = Imager::Search::Driver->new(
      driver => 'HTML24',
      big    => $large_imager_object,
      small  => $small_imager_object,
  );
  
  # Run the search
  my $found = $search->find_first;
  
  # Handle the result
  print "Found at row " . $found->top . " and column " . $found->left;

=head1 DESCRIPTION

Given two images (we'll call them Big and Small), where Small is
contained within Big zero or more times, determine the pixel locations
of Small within Big.

For example, given a screen shot or a rendered webpage, locate the
position of a known icon or picture within the larger image.

The intent is to provide functionality for use in various testing
scenarios, or desktop gui automation, and so on.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp         ();
use Params::Util qw{ _STRING _CODELIKE _SCALAR _INSTANCE };
use Imager       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}

use Imager::Search::Match ();





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $driver = Imager::Search::Driver->new;

The C<new> constructor takes a new search driver object.

Returns a new B<Imager::Search::Driver> object, or croaks on error.

=cut

sub new {
	my $class = shift;

	# Apply the default driver
	if ( $class eq 'Imager::Search::Driver' ) {
		require Imager::Search::Driver::HTML24;
		return  Imager::Search::Driver::HTML24->new(@_);
	}

	# Create the object
	my $self = bless { @_ }, $class;

	# Get the transforms
	unless ( _CODELIKE($self->transform_pattern_line) ) {
		Carp::croak("The small_transform param was not a CODE reference");
	}
	unless ( _CODELIKE($self->transform_pattern_newline) ) {
		Carp::croak("The transform_pattern_newline param was not a CODE reference");
	}

	return $self;
}




#####################################################################
# Driver API Methods

sub pattern_regexp {
	my $class = ref($_[0] || $_[0]);
	die "Illegal driver $class does not implement pattern_regexp";
}

sub pattern_lines {
	my $self   = shift;
	my $image  = shift;
	my $height = $image->getheight;	
	my @lines  = ();
	foreach my $row ( 0 .. $height - 1 ) {
		$lines[$row] = $self->pattern_line($image, $row);
	}
	return \@lines;
}

sub pattern_line {
	my ($self, $image, $row) = @_;

	# Get the colour array
	my $col  = -1;
	my $line = '';
	my $func = $self->transform_pattern_line;
	my $this = '';
	my $more = 1;
	foreach my $color ( $image->getscanline( y => $row ) ) {
		$col++;
		my $string = &$func( $color );
		unless ( _STRING($string) ) {
			Carp::croak("Did not generate a search string for cell $row,$col");
		}
		if ( $this eq $string ) {
			$more++;
			next;
		}
		$line .= ($more > 1) ? "(?:$this){$more}" : $this; # if $this; (conveniently works without the if) :)
		$more  = 1;
		$this  = $string;
	}
	$line .= ($more > 1) ? "(?:$this){$more}" : $this;

	return $line;
}

sub image_string {
	my $class = ref($_[0] || $_[0]);
	die "Illegal driver $class does not implement image_string";
}

sub match_object {
	my $self      = shift;
	my $image     = shift;
	my $pattern   = shift;
	my $character = shift;

	# Derive the pixel position from the character position
	my $pixel   = $self->match_pixel( $image, $pattern, $character );

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
	my $class = ref($_[0] || $_[0]);
	die "Illegal driver $class does not implement match_pixel";
}

1;

=pod

=head1 SUPPORT

See the SUPPORT section of the main L<Imager::Search> module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
