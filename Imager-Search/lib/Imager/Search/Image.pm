package Imager::Search::Image;

=pod

=head1 NAME

Imager::Search::Image - Generic interface for a searchable image

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use strict;
use Params::Util qw{ _POSINT _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( _POSINT($self->height) ) {
		Carp::croak("Missing or invalid height param");
	}
	unless ( _POSINT($self->width) ) {
		Carp::croak("Missing or invalid width param");
	}
	unless ( defined $self->string ) {
		Carp::croak("Missing or invalid string param");
	}
	if ( $self->{class} ) {
		if ( $self->{class} eq $class ) {
			delete $self->{class};
		} else {
			Carp::croak("Image class mismatch");
		}
	}

	return $self;
}

sub driver {
	$_[0]->{driver};
}

sub height {
	$_[0]->{height};
}

sub width {
	$_[0]->{width};
}

sub string {
	$_[0]->{string};
}





#####################################################################
# Search Methods

=pod

=head2 find

The C<find> method compiles the search and target images in memory, and
executes a single search, returning the position of the first match as a
L<Imager::Match::Occurance> object.

=cut

sub find {
	my $self = shift;

	# Get the search expression
        my $pattern = _INSTANCE(shift, 'Imager::Search::Pattern')
		or die "Did not pass a Pattern object to find";
	my $regexp  = $pattern->regexp( $self );

	# Run the search
	my @match = ();
	my $string   = $self->string;
	while ( scalar $$string =~ /$regexp/gs ) {
		my $p = $-[0];
		push @match, $self->driver->match_object( $self, $pattern, $p );
		pos $string = $p + 1;
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
	my $self = shift;

	# Get the search expression
        my $pattern = _INSTANCE(shift, 'Imager::Search::Pattern')
		or die "Did not pass a Pattern object to find";
	my $regexp  = $pattern->regexp( $self );

	# Run the search
	my $string = $self->string;
	while ( scalar $$string =~ /$regexp/gs ) {
		my $p     = $-[0];
		my $match = $self->driver->match_object( $self, $pattern, $p );
		unless ( defined $match ) {
			# False positive
			pos $string = $p + 1;
			next;
		}
		return $match;
	}
	return;
}

# Derived from find_first, but always return a scalar boolean
sub find_any {
	my $self  = shift;
	return !! $self->find_first( @_ );
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
