package Imager::Search::Driver;

=pod

=head1 NAME

Imager::Search::Driver - Locate an image inside another image

=head1 SYNOPSIS

  # Create the search
  my $search = Imager::Search::Driver->new(
      driver => 'HTML8',
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
use Carp         ();
use Params::Util qw{ _STRING _CODELIKE _SCALAR _INSTANCE };
use Imager       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}





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
		require Imager::Search::Driver::HTML8;
		return  Imager::Search::Driver::HTML8->new(@_);
	}

	# Create the object
	my $self = bless { @_ }, $class;

	# Get the transforms
	unless ( _CODELIKE($self->transform_pattern_line) ) {
		Carp::croak("The small_transform param was not a CODE reference");
	}
	unless ( _CODELIKE($self->transform_image_line) ) {
		Carp::croak("The big_transform param was not a CODE reference");
	}
	unless ( _CODELIKE($self->transform_pattern_newline) ) {
		Carp::croak("The transform_pattern_newline param was not a CODE reference");
	}

	return $self;
}




#####################################################################
# Driver API Methods

sub pattern_lines {
	my $self   = shift;
	my $image  = shift;
	my $height = $image->getheight;	
	my @lines  = ();
	foreach my $row ( 0 .. $height - 1 ) {
		$lines[$row] = $self->pattern_scanline($image, $row);
	}
	return \@lines;
}

sub pattern_scanline {
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
	my $self       = shift;
	my $scalar_ref = shift;
	my $image      = shift;
	my $height     = $image->getheight;
	my $func       = $self->transform_image_line;
	foreach my $row ( 0 .. $height - 1 ) {
		# Get the string for the row
		$$scalar_ref = join('',
			map { &$func( $_ ) }
			$image->getscanline( y => $row )
		);
	}

	# Return the scalar reference as a convenience
	return $scalar_ref;
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
