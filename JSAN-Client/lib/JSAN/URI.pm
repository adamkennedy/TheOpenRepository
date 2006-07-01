package JSAN::URI;

=pod

=head1 NAME

JSAN::URI - A JavaScript Archive Network (JSAN) Validating Mirror URI

=head1 SYNOPSIS

  my $url = 'http://www.jsan.de';
  
  # Create the mirror handle
  my $mirror = JSAN::URI->new( $url );
  
  # Check the mirror
  if ( ! $mirror->valid ) {
  	die "The mirror does not exist";
  }
  if ( $mirror->age > (3600 * 48) ) {
  	die "The mirror is too old";
  }

=head1 DESCRIPTION

The JavaScript Archive Network (JSAN) uses a mirror synchronisation
method originally invented for the Comprehensive Perl Archive Network
(CPAN) which involved created a tiny specially named file in the root
of the filesystem that contains a timestamp, updated whenever the index
is regenerated.

By retrieving and examining this file, it is possible to validate if a
given URL actually represents a JSAN mirror, and how up to date that
mirror is, compared to the master site.

This module implements the logic required to do this in a reusable form

=head1 METHODS

=cut

use strict;
use URI              ();
use LWP::Simple      ();
use Config::Tiny     ();
use File::Spec::Unix ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}

use constant JSAN_MASTER => 'http://master.openjsan.org/';




#####################################################################
# Constructor and Accessors

=pod

=head2 new $uri

The C<new> constructor takes a path to the base of a JSAN mirror and
creates a handle object for it.

Returns a C<JSAN::URI> object, or C<undef> if not passed
a valid url path.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $URI   = URI->new(shift) or return undef;

	# Create the object
	my $self = bless {
		URI    => $URI->canonical,
		config => undef,
		master => undef,
		}, $class;

	$self;
}

=pod

=head2 URI

The C<URI> accessor returns a L<URI> object for the location of the mirror.

=cut

sub URI { $_[0]->{URI} }

=pod

=head2 uri

The C<uri> accessor returns a string of the location of the mirror.

=cut

sub uri { $_[0]->{URI}->as_string }

sub as_string { $_[0]->uri }





#####################################################################
# JSAN::URI Methods

=pod

=head2 valid

The C<valid> method check to see if the mirror exists, that is has
the mirror.conf file, and that matches the expected content.

Returns true if the mirror is valid, or false otherwise.

=cut

sub valid {
	my $self   = shift;
	my $config = $self->_config or return '';
	!! (defined $config->{mirror} and $config->{mirror} eq 'jsan');
}







#####################################################################
# Support Methods

# Get the Config::Tiny object for the mirror
sub _config {
	my $self = shift;
	$self->{config} or
	$self->{config} = $self->_get( $self->uri );
}

# Get the Config::Tiny object for the master
sub _master {
	my $self = shift;
	$self->{master} or
	$self->{master} = $self->_get( JSAN_MASTER );
}

# Takes a URI and returns a Config::Tiny object for it
sub _get {
	my ($self, $uri) = @_;
	$uri =~ s{/?$}{/mirror.conf}s;
	my $content = LWP::Simple::get($uri);
	return undef unless defined $content;
	Config::Tiny->read_string( $content );
}

1;

=pod

=head1 TO DO

- Add verbose support

- Finish this when the mirrors have mirror.conf files

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Client>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
