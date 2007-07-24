package Imager::Search;

=pod

=head1 NAME

Imager::Search - Locate an imager inside another image

=head1 SYNOPSIS

  The author is an idiot who forgot to write the synopsis

=head1 DESCRIPTION

This module is designed to solve a conceptually simple problem.

Given two images (we'll call them Big and Small), where Small is
contained within Big zero or more times, determine the pixel locations
of Small within Big.

For example, given a screen shot or a rendered webpage, locate the
position of a known icon or picture within the larger image.

The intent is to provide functionality for use in various testing
scenarios.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp         ();
use Params::Util qw{ _INSTANCE _STRING _CODELIKE };
use Imager       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $search = Imager::Search->new(
      driver => 'WebColour',
      big    => $large_imager_object,
      small  => $small_imager_object,
  );

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

sub big {
	$_[0]->{big};
}

sub small {
	$_[0]->{small};
}






#####################################################################
# Main Methods

sub find_first {
	my $self  = shift;
	my $big   = $self->big_string;
	my $small = $self->small_string;
	$$big =~ /^(.+?)$$small/s or return undef;
	return $self->_position(length $1);
}

sub big_string {
	my $self   = shift;
	my $height = $self->big->getheight;
	my $string = '';
	foreach my $row ( 0 .. $height - 1 ) {
		$string .= $self->big_scanline($row);
	}
	return \$string;
}

sub big_scanline {
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

sub small_string {
	my $self    = shift;
	my $height  = $self->small->getheight;
	my $pixels  = $self->big->getwidth - $self->small->getwidth;
	my $func    = $self->{newline_transform};
	my $newline = &$func( $pixels );
	my $string  = $self->small_scanline(0);
	foreach my $row ( 1 .. $height - 1 ) {
		$string .= $newline . $self->small_scanline($row);
	}
	return \$string;
}

sub small_scanline {
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





#####################################################################
# Support Methods

sub _position {
	my ($self, $chars) = @_;
	my $width    = $self->big->getwidth;
	my %position = (
		x => $chars % $width,
		y => int($chars / $width),
	);
	return \%position;
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

