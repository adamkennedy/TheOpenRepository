package POE::Declare::HTTP::Server;

=pod

=head1 NAME

POE::Declare::HTTP::Server - A simple HTTP server based on POE::Declare

=head1 SYNOPSIS

    # Create the web server
    my $server = POE::Declare::HTTP::Server->new(
        Hostname => '127.0.0.1',
        Port     => '8010',
        Handler  => sub {
            my $request  = shift;
            my $response = shift;
    
            # Your webby stuff here...
    
            return;
        },
    );
    
    # Control with methods
    $server->start;
    $server->stop;

=head1 DESCRIPTION

This module allows creation of a simple HTTP server based on L<POE::Declare>.

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





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $server = POE::Declare::HTTP::Server->new(
        Hostname => '127.0.0.1',
        Port     => '8010',
        Handler  => \&content,
    );

The C<new> constructor sets up a reusable HTTP server that can be enabled
and disabled repeatedly as needed.

It takes three required parameters parameters. C<Hostname>, C<Port> and
C<Handler>.

The C<Handler> parameter should be a C<CODE> reference that will be passed
a L<HTTP::Request> object and a L<HTTP::Response> object. Your code should
examine the request object, and fill the provided response object.

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

=pod

=head2 Hostname

The C<Hostname> accessor returns the server to bind to, as originally
provided to the constructor.

=head2 Port

The C<Port> accessor returns the port number to bind to, as originally
provided to the constructor.

=head2 Handler

The C<Handler> accessor returns the C<CODE> reference that requests
will be passed to, as provided to the constructor.

=cut

use POE::Declare 0.50 {
	Hostname => 'Param',
	Port     => 'Param',
	Handler  => 'Param',
	server   => 'Internal',
	socket   => 'Internal',
};





######################################################################
# Control Methods

=pod

=head2 start

The C<start> method enables the web server. If the server is already running,
this method will shortcut and do nothing.

If called before L<POE> has been started, the web server will start
immediately once L<POE> is running.

=cut

sub start {
	my $self = shift;
	unless ( $self->spawned ) {
		$self->spawn;
		$self->post('startup');
	}
	return 1;
}

=pod

=head2 stop

The C<stop> method disables the web server. If the server is not running,
this method will shortcut and do nothing.

=cut

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

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-HTTP-Server>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
