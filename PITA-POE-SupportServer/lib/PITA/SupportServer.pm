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
	my $self = shift->SUPER::new(@_);

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
		PingEvent     => $self->lookback('http_ping'),
		MirrorEvent   => $self->lookback('http_mirror'),
		UploadEvent   => $self->lookback('http_upload'),
	) or die "Failed to create HTTP server";

	return $self;
}

use POE::Declare 0.50 {
	Hostname      => 'Param',
	Port          => 'Param',
	Program       => 'Param',
	Files         => 'Param',
	StartupEvent  => 'Message',
	ShutdownEvent => 'Message',
	http          => 'Internal',
	execute       => 'Internal',
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
	$_[SELF]->startup_timeout_start;
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

sub http_ping : Event {
	$_[SELF]->startup_timeout_stop;
	$_[SELF]->activity_timeout_start;
}

sub http_mirror : Event {
	$_[SELF]->activity_timeout_start;	
}

sub http_upload : Event {
	$_[SELF]->activity_timeout_start;
	$_[SELF]->{Files}->{$_[ARG1]} = $_[ARG2];

	# Do we have everything?
	unless ( grep { not defined $_ } values %{$_[SELF]} ) {
		$_[SELF]->activity_timeout_stop;
		$_[SELF]->post('execute_shutdown');
	}
}

sub execute_startup : Event {
	$_[SELF]->{execute} = POE::Wheel::Run->new(
		Program    => $_[SELF]->Program,
		CloseEvent => $_[SELF]->lookback('execute_close'),
	) or die "Failed to create POE::Wheel::Run";
}

sub execute_shutdown : Event {
	$_[SELF]->shutdown_timeout_start;
}

sub execute_close : Event {
	
}

sub startup_timeout : Timeout(30) {

}

sub activity_timeout : Timeout(3600) {

}

sub shutdown_timeout : Timeout(60) {

}

sub shutdown : Event {
	$_[SELF]->finish;
	$_[SELF]->ShutdownEvent;
}

1;
