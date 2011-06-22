package POE::Declare::Log::File;

=pod

=head1 NAME

POE::Declare::Log::File - A simple HTTP client based on POE::Declare

=head1 SYNOPSIS

    # Create the web server
    my $http = POE::Declare::Log::File->new(
        File => '/var/log/my.log',
    );
    
    # Control with methods
    $http->start;
    $http->GET('http://google.com');
    $http->stop;

=head1 DESCRIPTION

This module provides a simple logging module which spools output to a file,
queueing and batching messages in memory if the message rate exceeds the
responsiveness of the filesystem.

The implemenetation is intentionally minimalist and has no dependencies beyond
those of L<POE::Declare> itself, which makes this module useful for simple
utility logging or debugging systems.

=head1 METHODS

=cut

use 5.008;
use strict;
use Carp                  ();
use Symbol                ();
use POE             1.293 ();
use POE::Wheel::ReadWrite ();

our $VERSION = '0.01';

use POE::Declare 0.54 {
	Filename => 'Param',
	Handle   => 'Param',
	wheel    => 'Internal',
	queue    => 'Internal',
	state    => 'Internal',
};





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $server = POE::Declare::Log::File->new(
        Filename      => 
        ShutdownEvent => \&on_shutdown,
    );

The C<new> constructor sets up a reusable HTTP client that can be enabled
and disabled repeatedly as needed.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Open the file if needed
	if ( $self->Filename and not $self->Handle ) {
		my $filename = $self->Filename;
		my $handle   = Symbol::gensym();
		if ( open( $handle, '>>', $filename ) {
			$self->{Handle} = $handle;
		} else {
			Carp::croak("Failed to open $filename");
		}
	}
	unless ( $self->Handle ) {
		Carp::croak("Did not provide a Filename or Handle param");
	}

	# Create the message queue
	$self->{state} = 'STOP';
	$self->{queue} = [ ];

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

=pod

=head2 print

    $log->print("This is a log message");

Writes one or more messages to the log.

=cut

sub print {
	my $self = shift;

	# Add the messages to the queue of pending output
	push @{$self->{queue}}, @_;

	# Initiate a flush event if we aren't doing one already
	if ( $self->{state} eq 'READY' ) {
		$self->post('flush');
		return 1;
	}

	# Message is delayed
	return 0;
}





######################################################################
# Event Methods

sub startup : Event {
	# Create the read/write wheel on the filehandle
	$_[SELF]->{wheel} = 
}

sub shutdown : Event {
	$_[SELF]->finish;
	$_[SELF]->ShutdownEvent;
}





######################################################################
# POE::Declare::Object Methods

sub finish {
	my $self = shift;

	# If we opened a file, close it
	if ( $self->Filename ) {
		close delete $self->{Handle};
	}

	# Clean out the POE::Declare object as normal
	$self->SUPER::finish(@_);
}

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-HTTP-Client>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
