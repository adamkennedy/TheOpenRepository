package Imager::Search;

=pod

=head1 NAME

Imager::Search - Locate an image inside another image

=head1 SYNOPSIS

  # Create the search
  my $search = Imager::Search::RRBBGG->new(
      big    => $large_imager_object,
      small  => $small_imager_object,
  );
  
  # Run the search
  my $found = $search->find_first;
  
  # Handle the result
  print "Found at row " . $found->top . " and column " . $found->left;

=head1 DESCRIPTION

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
use Carp                  ();
use Params::Util          qw{ _INSTANCE _STRING _CODELIKE };
use Imager                ();
use Imager::Search::Match ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $search = Imager::Search::RRBBGG->new(
      big    => $large_imager_object,
      small  => $small_imager_object,
  );

The C<new> constructor takes a new search object.

It takes two parameters by by default, for clarity simply named C<big>
and C<small>. Both should be L<Imager> objects.

The C<small> param is the image you are searching B<for>, and the C<big>
param is the image you will be searching B<in>.

Returns a new B<Imager::Search> object, or croaks on error.

=cut

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check the big image
	unless ( _INSTANCE($self->big, 'Imager') ) {
		Carp::croak("The big param is not an Imager object");
	}
	unless ( defined $self->big->getheight ) {
		Carp::croak("The big param does not have a height");
	}
	unless ( defined $self->big->getwidth ) {
		Carp::croak("The big param does not have a width");
	}

	# Check the small image
	unless ( _INSTANCE($self->small, 'Imager') ) {
		Carp::croak("The small param is not an Imager object");
	}
	unless ( defined $self->small->getheight ) {
		Carp::croak("The small param does not have a height");
	}
	unless ( defined $self->small->getwidth ) {
		Carp::croak("The small param does not have a width");
	}

	# Get the transforms
	$self->{small_transform} ||= $self->small_transform;
	unless ( _CODELIKE($self->{small_transform}) ) {
		Carp::croak("The small_transform param was not a CODE reference");
	}
	$self->{big_transform} ||= $self->big_transform;
	unless ( _CODELIKE($self->{big_transform}) ) {
		Carp::croak("The big_transform param was not a CODE reference");
	}
	$self->{newline_transform} ||= $self->newline_transform;
	unless ( _CODELIKE($self->{newline_transform}) ) {
		Carp::croak("The newline_transform param was not a CODE reference");
	}

	return $self;
}

=pod

=head2 big

The C<big> accessor returns the original big L<Imager> object.

=cut

sub big {
	$_[0]->{big};
}

=pod

=head2 small

The C<small> accessor returns the original small L<Imager> object.

=cut

sub small {
	$_[0]->{small};
}






#####################################################################
# Main Methods

=pod

=head2 find_first

The C<find_first> method is the only one implemented in this first release
of L<Imager::Search>.

It compiles the search and target images in memory, and executes a single
search, returning the position of the first match as a
L<Imager::Search::Match> object.

=cut

sub find_first {
	my $self  = shift;
	my $big   = $self->_big_string;
	my $small = $self->_small_string;
	$$big =~ /^(.+?)$$small/s or return undef;
	return Imager::Search::Match->from_position(
		$self, length($1),
		);
}





#####################################################################
# Support Methods

sub _big_string {
	my $self   = shift;
	my $height = $self->big->getheight;
	my $string = '';
	foreach my $row ( 0 .. $height - 1 ) {
		$string .= $self->_big_scanline($row);
	}
	return \$string;
}

sub _big_scanline {
	my $self = shift;
	my $row  = shift;

	# Get the colour array
	my $col  = 0;
	my $line = '';
	my $func = $self->{big_transform};
	foreach my $color ( $self->big->getscanline( y => $row ) ) {
		my $string = &$func( $color );
		unless ( _STRING($string) ) {
			Carp::croak("Did not generate a search string for cell $row,$col");
		}
		$line .= $string;
		$col++;
	}

	return $line;
}

sub _small_string {
	my $self    = shift;
	my $height  = $self->small->getheight;
	my $pixels  = $self->big->getwidth - $self->small->getwidth;
	my $func    = $self->{newline_transform};
	my $newline = &$func( $pixels );
	my $string  = $self->_small_scanline(0);
	foreach my $row ( 1 .. $height - 1 ) {
		$string .= $newline . $self->_small_scanline($row);
	}
	return \$string;
}

sub _small_scanline {
	my $self = shift;
	my $row  = shift;

	# Get the colour array
	my $col  = -1;
	my $line = '';
	my $func = $self->{small_transform};
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

