package PITA::SupportServer;

use 5.008;
use strict;
use warnings;
use Params::Util              ();
use POE::Wheel::Run           ();
use PITA::SupportServer::HTTP ();

our $VERSION = '0.50';





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(
		StartupTimeout  => 30,
		ActivityTimeout => 3600,
		ShutdownTimeout => 60,
		@_,
	);

	# Check params
	unless ( Params::Util::_ARRAY($self->Execute) ) {
		die "Missing or invalid 'Execute' param";
	}

	# Create the web server
	$self->{http} = PITA::SupportServer::HTTP->new(
		Hostname      => $self->Hostname,
		Port          => $self->Port,
		StartupEvent  => $self->lookback('http_startup_event'),
		StartupError  => $self->lookback('http_startup_error'),
		ShutdownEvent => $self->lookback('http_shutdown_event'),
	) or die "Failed to create HTTP server";

	return $self;
}

use POE::Declare 0.50 {
	Hostname        => 'Param',
	Port            => 'Param',
	Program         => 'Param',
	StartupTimeout  => 'Param',
	ActivityTimeout => 'Param',
	ShutdownTimeout => 'Param',
	StartupEvent    => 'Message',
	ShutdownEvent   => 'Message',
	http            => 'Internal',
	execute         => 'Internal',
}





######################################################################
# Main Methods

sub run {
	$_[0]->start;
	POE::Kernel->run;
	return 1;
}

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
	# Kick off the blanket startup timeout
	$_[SELF]->startup_timeout_start( $_[SELF]->StartupTimeout );
	$_[SELF]->post('http_startup');
}

sub http_startup : Event {
	$_[SELF]->{http}->startup;
}

sub http_startup_event : Event {
	$_[SELF]->execute_startup;
}

sub http_startup_error : Event {
	die "Failed to start the web server";
}

sub execute_startup : Event {
	$_[SELF]->{execute} = POE::Wheel::Run->new(
		Program    => $_[SELF]->Program,
		CloseEvent => $_[SELF]->lookback('execute_close'),
	) or die "Failed to create POE::Wheel::Run";
}

sub startup_timeout : Timeout {

}

sub activity_timeout : Timeout {

}

sub shutdown_timeout : Timeout {

}

sub shutdown : Event {
	$_[SELF]->finish;
	$_[SELF]->ShutdownEvent;
}

1;
