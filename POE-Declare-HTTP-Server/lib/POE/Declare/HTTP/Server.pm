package POE::Declare::HTTP::Server;

=pod

=head1 NAME

POE::Declare::HTTP::Server - A simple HTTP server based on POE::Declare

=head1 SYNOPSIS

  
=head1 DESCRIPTION

This module demonstrates a simple HTTP server based on L<POE::Declare>.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Params::Util         1.00 ();
use HTTP::Headers       5.835 ();
use HTTP::Request       5.827 ();
use HTTP::Response      5.836 ();
use POE                 1.299 ();
use POE::Filter::HTTPD  1.299 ();
use POE::Wheel::ReadWrite     ();
use POE::Wheel::SocketFactory ();

our $VERSION = '0.01';

use POE::Declare 0.50 {
	Hostname => 'Param',
	Port     => 'Param',
	Handler  => 'Param',
	server   => 'Internal',
	socket   => 'Internal',
};





######################################################################
# Constructor and Accessors

=pod

=head2 new

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( Params::Util::_STRING($self->Hostname) ) {
		die "Missing or invalid Hostname param";
	}
	unless ( Params::Util::_POSINT($self->Port) ) {
		die "Missing or invalid Port param";
	}
	unless ( Params::Util::_CODE($self->Handler) ) {
		die "Missing or invalid Handler param";
	}

	return $self;
}





######################################################################
# Control Methods

sub start {
	my $self = shift;
	unless ( $self->spawned ) {
		$self->spawn;
		$self->post('startup');
	}
	return 1;
}

sub stop {
	my $self = shift;
	if ( $self->spawned ) {
		$self->post('shutdown');
	}
	return 1;
}





######################################################################
# Event Methods

sub startup : Event {

	# Create the socket factory
	$_[SELF]->{server} = POE::Wheel::SocketFactory->new(
		Reuse        => 1,
		BindPort     => $_[SELF]->Port,
		SuccessEvent => 'connect',
		FailureEvent => 'error',
	) or die 'Failed to create socket factory';

	return;
}

sub connect : Event {
	# We can only deal with one request at a time.
	$_[SELF]->{server}->pause_accept;

	# Create the socket
	$_[SELF]->{socket} = POE::Wheel::ReadWrite->new(
		Filter       => POE::Filter::HTTPD->new,
		Handle       => $_[ARG0],
		InputEvent   => 'request',
		FlushedEvent => 'flushed',
		ErrorEvent   => 'dropped',
	);

	return;
}

sub request : Event {

	# Create the default response
	my $response = HTTP::Response->new( 200 );

	# Pass the request for processing
	$_[SELF]->Handler->( $_[ARG0], $response );

	# Send the response back to the client
	$_[SELF]->{socket}->put( $response );

	# Return and wait for the socket to flush
	return;
}

sub flushed : Event {

	# Clean up and prepare for the next request
	$_[SELF]->{socket} = undef;
	if ( $_[SELF]->{server} ) {
		$_[SELF]->{server}->resume_accept;
	}

	return;
}

sub dropped : Event {

	# Clean up and prepare for the next request
	$_[SELF]->{socket} = undef;
	if ( $_[SELF]->{server} ) {
		$_[SELF]->{server}->resume_accept;
	}

	return;
}

sub shutdown : Event {

	# Shut down the server and any active connection
	$_[SELF]->{server} = undef;
	$_[SELF]->{socket} = undef;

}

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
