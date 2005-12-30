package PITA::Host::ResultServer;

=pod

=head1 NAME

PITA::Host::ResultServer - Accepts PITA-XML reports produced by testing images

=head1 DESCRIPTION

Because each testing image is a black box with potentially different and
unusual properties, a consistent method is needed to get the results
report out of the image and return them to the PITA Host.

One relatively common mechanism all testing images should have is the
ability to connect to the host over the network. Because of this, a
method for returning image results can be used whereby a HTTP server
is created on the Host to listen for incoming "file uploads" from the
test images.

This class implements such a web server.

=head1 METHODS

=cut

use strict;
use Carp         ();
use Params::Util '_POSINT';
use HTTP::Daemon ();
use HTTP::Status ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the params
	unless ( $self->{LocalAddr} ) {
		Carp::croak("Did not provide a 'LocalAddr' to ::ResultServer->new");
	}
	unless ( $self->{LocalPort} ) {
		Carp::croak("Did not provide a 'LocalPort' to ::ResultServer->new");
	}

	$self;
}

sub LocalAddr { $_[0]->{LocalAddr} }

sub LocalPort { $_[0]->{LocalPort} }





#####################################################################
# Main Methods

sub run {
	my $self = shift;

	# Create and launch the HTTP Daemon
	my $d = HTTP::Daemon->new(
		LocalAddr => $self->LocalAddr,
		LocalPort => $self->LocalPort,
		);

	
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2001 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
