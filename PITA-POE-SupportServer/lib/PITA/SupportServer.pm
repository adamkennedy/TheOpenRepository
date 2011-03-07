package PITA::SupportServer;

use 5.008;
use strict;
use warnings;
use Params::Util               1.00 ();
use POE::Wheel::Run           1.299 ();
use POE::Declare::HTTP::Server 0.03 ();
use PITA::SupportServer::HTTP       ();

our $VERSION = '0.50';

use POE::Declare 0.51 {
	Hostname      => 'Param',
	Port          => 'Param',
	Program       => 'Param',
	Files         => 'Param',
	Mirrors       => 'Param',
	StartupEvent  => 'Message',
	ShutdownEvent => 'Message',
	status        => 'Internal',
	http          => 'Internal',
	execute       => 'Internal',
};

use constant {
	STOPPED  => 1,
	STARTING => 1,
	RUNNING  => 1,
	STOPPING => 1,
};





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Set up tracking variables
	$self->{status} = STOPPED;

	# Check params
	unless ( Params::Util::_ARRAY($self->Program) ) {
		die "Missing or invalid 'Program' param";
	}

	# Create the web server
	$self->{http} = PITA::SupportServer::HTTP->new(
		Hostname      => $self->Hostname,
		Port          => $self->Port,
		Mirrors       => $self->Mirrors,
		StartupEvent  => $self->lookback('http_startup_event'),
		StartupError  => $self->lookback('http_startup_error'),
		ShutdownEvent => $self->lookback('http_shutdown_event'),
		PingEvent     => $self->lookback('http_ping'),
		MirrorEvent   => $self->lookback('http_mirror'),
		UploadEvent   => $self->lookback('http_upload'),
	) or die "Failed to create HTTP server";

	return $self;
}










######################################################################
# Main Methods

# Sort of half-assed Process compatibility for testing purposes
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
	$_[SELF]->{status} = STARTING;
	$_[SELF]->startup_timeout_start;
	$_[SELF]->post('http_startup');
}

sub http_startup : Event {
	$_[SELF]->{http}->start;
}

sub http_startup_event : Event {
	$_[SELF]->post('execute_startup');
}

sub http_startup_error : Event {
	die "Failed to start the web server";
}

sub http_shutdown_event : Event {

}

sub http_ping : Event {
	$_[SELF]->{status} = RUNNING;
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
		$_[SELF]->{status} = STOPPING;
		$_[SELF]->activity_timeout_stop;
		$_[SELF]->shutdown_timeout_start;
	}
}

sub execute_startup : Event {
	$_[SELF]->{execute} = POE::Wheel::Run->new(
		Program     => $_[SELF]->Program,
		StdoutEvent => $_[SELF]->lookback('execute_stdout'),
		StderrEvent => $_[SELF]->lookback('execute_stderr'),
		CloseEvent  => $_[SELF]->lookback('execute_close'),
	) or die "Failed to create POE::Wheel::Run";
}

sub execute_stdout : Event {
	# Do nothing for now
}

sub execute_stderr : Event {
	# Do nothing for now
}

sub execute_close : Event {
	print "Program terminated";
	$_[SELF]->post('shutdown');
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





######################################################################
# Support Methods

sub finish {
	my $self = shift;

	# Clean up our children
	if ( $self->{execute} ) {
		$self->{execute}->kill(9);
		$self->{execute} = undef;
	}
	if ( $self->{http}->spawned ) {
		$self->{http}->call('shutdown');
	}

	# Call parent method to clean out other things
	$self->SUPER::finish(@_);
}

compile;
