package Imager::Match;

=pod

=head1 NAME

Imager::Match - Locate an image inside another image

=head1 SYNOPSIS

  # Create the search
  my $search = Imager::Match::RRBBGG->new(
      big    => $large_imager_object,
      small  => $small_imager_object,
  );
  
  # Run the search
  my $found = $search->find_first;
  
  # Handle the result
  print "Found at row " . $found->top . " and column " . $found->left;

=head1 DESCRIPTION

B<THIS MODULE IS CONSIDERED EXPERIMENTAL AND SUBJECT TO CHANGE>

This module is designed to solve a conceptually simple problem.

Given two images (we'll call them Big and Small), where Small is
contained within Big zero or more times, determine the pixel locations
of Small within Big.

For example, given a screen shot or a rendered webpage, locate the
position of a known icon or picture within the larger image.

The intent is to provide functionality for use in various testing
scenarios, or desktop gui automation, and so on.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp                          ();
use Params::Util                  qw{ _INSTANCE _STRING _CODELIKE };
use Imager                        ();
use Imager::Search::Match         ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $search = Imager::Search::Driver::HTML8;

The C<new> constructor takes a new search driver object.

Returns a new B<Imager::Search::Driver> object, or croaks on error.

=cut

sub new {
	my $class = shift;

	# Apply the default driver
	if ( $class eq 'Imager::Search::Driver' ) {
		require Imager::Search::Driver::HTML8;
		return  Imager::Search::Driver::HTML8->new(@_);
	}

	# Create the object
	my $self = bless { @_ }, $class;

	# Get the transforms
	unless ( _CODELIKE($self->pattern_transform) ) {
		Carp::croak("The small_transform param was not a CODE reference");
	}
	unless ( _CODELIKE($self->image_transform) ) {
		Carp::croak("The big_transform param was not a CODE reference");
	}
	unless ( _CODELIKE($self->newline_transform) ) {
		Carp::croak("The newline_transform param was not a CODE reference");
	}

	return $self;
}




#####################################################################
# Support Methods

sub _small_string {
	my $self        = shift;
	my $scalar_ref  = shift;
	my $height      = $self->small->getheight;
	my $nl_width    = $self->big->getwidth - $self->small->getwidth;
	my $nl_function = $self->newline_transform;
	my $nl_string   = &$nl_function( $nl_width );
	foreach my $row ( 0 .. $height - 1 ) {
		$$scalar_ref .= $nl_string if $row;
		$$scalar_ref .= $self->_small_scanline($row);
	}

	# Return the scalar reference as a convenience
	return $scalar_ref;
}

sub _small_scanline {
	my $self = shift;
	my $row  = shift;

	# Get the colour array
	my $col  = -1;
	my $line = '';
	my $func = $self->small_transform;
	my $this = '';
	my $more = 1;
	foreach my $color ( $self->small->getscanline( y => $row ) ) {
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

sub _big_string {
	my $self       = shift;
	my $scalar_ref = shift;
	my $height     = $self->big->getheight;
	my $func       = $self->big_transform;
	foreach my $row ( 0 .. $height - 1 ) {
		# Get the string for the row
		my $col = 0;
		foreach my $color ( $self->big->getscanline( y => $row ) ) {
			my $pixel = &$func( $color );
			unless ( _STRING($pixel) ) {
				Carp::croak("Did not generate a search string for cell $row,$col");
			}
			$$scalar_ref .= $pixel;
			$col++;
		}
	}

	# Return the scalar reference as a convenience
	return $scalar_ref;
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

