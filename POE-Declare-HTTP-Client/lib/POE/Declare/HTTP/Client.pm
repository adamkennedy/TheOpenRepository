package POE::Declare::HTTP::Client;

=pod

=head1 NAME

POE::Declare::HTTP::Client - A simple HTTP client based on POE::Declare

=head1 SYNOPSIS

    # Create the web server
    my $http = POE::Declare::HTTP::Client->new(
        Hostname => '127.0.0.1',
        Port     => '80',
        Handler  => sub {
            my $server   = shift;
            my $response = shift;
    
            # The request is not passed to you but is available if needed
            my $request = $response->request;
    
            # Webby content generation stuff here
            $response->code( 200 );
            $response->header( 'Content-Type' => 'text/plain' );
            $response->content( "Hello World!" );
    
            return;
        },
    );
    
    # Control with methods
    $http->start;
    $http->stop;

=head1 DESCRIPTION

This module provides a simple HTTP client based on L<POE::Declare>.

The implemenetation is intentionally minimalist, making this module an ideal
choice for creating specialised web clients embedded in larger applications.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Scalar::Util              1.19 ();
use Params::Util              1.00 ();
use HTTP::Request            5.827 ();
use HTTP::Request::Common          ();
use HTTP::Response           5.830 ();
use POE                      1.299 ();
use POE::Filter::HTTP::Parser 1.04 ();
use POE::Wheel::ReadWrite          ();
use POE::Wheel::SocketFactory      ();

our $VERSION = '0.01';

use POE::Declare 0.50 {
	Timeout         => 'Param',
	ResponseHandler => 'Param',

	request         => 'Internal',
	factory         => 'Internal',
	socket          => 'Internal',
};





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $server = POE::Declare::HTTP::Client->new(
        ResponseHandler => \&on_response,
    );

The C<new> constructor sets up a reusable HTTP client that can be enabled
and disabled repeatedly as needed.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Processing state
	$self->{request} = { };
	$self->{factory} = { };
	$self->{socket}  = { };

	return $self;
}





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

=pod

=head2 get

    $client->get('http://www.cpan.org/');

The C<get> method fetches a named URL via an HTTP GET.

=cut

sub GET {
	shift->request(
		HTTP::Request::Common::GET(@_)
	);
}

=pod

=head2 post

    $client->post('http://www.cpan.org/');

The C<get> method fetches a named URL via an HTTP POST.

=cut

sub POST {
	shift->request(
		HTTP::Request::Common::POST(@_)
	);
}

=pod

=head2 request

    $client->request( $request_object );

=cut

sub request {
	my $self    = shift;
	my $request = shift;
	unless ( Params::Util::_INSTANCE($request, 'HTTP::Request') ) {
		die "Missing or invalid HTTP::Request object";
	}

	# Are we already processing this request
	my $addr = Scalar::Util::refaddr($request);
	if ( $self->{request}->{$addr} ) {
		die "The request is already being processed";
	} else {
		$self->{request}->{$addr} = $request;
	}

	# Hand off to the event that starts the request
	$self->post( connect => $addr );
}








######################################################################
# Event Methods

sub connect {
	my $addr    = $_[ARG0];
	my $request = $_[SELF]->{request}->{$addr} or return;
	my $host    = $request->uri->host          or return;
	my $port    = $request->uri->port || 80;

	# Create the socket factory for the request
	
}

# Clean up and signal failure
sub error : Event {
	$_[SELF]->finish;
	$_[SELF]->StartupError;
}

sub connect : Event {
	# This initial implementation only deals with one request at a time.
	# It has the side effect of allowing the request handler to block for
	# a fairly long period of time without too much of an issue.
	$_[SELF]->{server}->pause_accept;

	# Create the socket
	$_[SELF]->{client} = POE::Wheel::ReadWrite->new(
		Filter       => POE::Filter::HTTPD->new,
		Handle       => $_[ARG0],
		InputEvent   => 'request',
		FlushedEvent => 'disconnect',
		ErrorEvent   => 'disconnect',
	);
}

sub request : Event {

	# Create the default response.
	# We default to a server error so that the appropriate return is used
	# if the Handler fails or somehow does nothing to the response.
	my $response = HTTP::Response->new( 500 );
	$response->request( $_[ARG0] );

	# Pass the response (and the request within it) to the handler.
	# Prevent an exception in the handler crashing the entire server.
	eval {
		$_[SELF]->Handler->( $_[SELF], $response );
	};

	# Send the response back to the client.
	# The just wait for the socket to flush
	$_[SELF]->{client}->put( $response );
}

sub disconnect : Event {
	# Handle stray events arriving after intentional shutdown
	$_[SELF]->{server} or return;

	# Clean up the current request, and open up for the next one
	$_[SELF]->{client} = undef;
	$_[SELF]->{server}->resume_accept;
}

sub shutdown : Event {
	$_[SELF]->finish;
	$_[SELF]->ShutdownEvent;
}





######################################################################
# POE::Declare::Object Methods

sub finish {
	my $self = shift;

	# Clear out the server and any active connection
	$self->{server} = undef;
	$self->{client} = undef;

	# Call parent method to clean out other things
	$self->SUPER::finish(@_);
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
