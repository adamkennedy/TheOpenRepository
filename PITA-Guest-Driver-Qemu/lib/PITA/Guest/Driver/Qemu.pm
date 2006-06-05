package PITA::Guest::Driver::Qemu;

=pod

=head1 NAME

PITA::Guest::Driver::Qemu - PITA Guest Driver for Qemu images

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use 5.005;
use strict;
use base 'PITA::Guest::Driver::Image';
use version          ();
use Carp             ();
use URI              ();
use File::Temp       ();
use File::Which      ();
use File::Remove     ();
use Params::Util     '_POSINT';
use Filesys::MakeISO ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.21';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Locate the qemu binary
	$self->{qemu_bin} = File::Which::which('qemu') unless $self->qemu_bin;
	unless ( $self->qemu_bin ) {
		Carp::croak("Cannot locate qemu, requires explicit param");
	}
	unless ( -x $self->qemu_bin ) {
		Carp::croak("Insufficient permissions to run qemu");
	}

	# Find the install qemu version
	my $qemu_bin = $self->qemu_bin;
	my @lines    = `$qemu_bin`;
	unless ( $lines[0] =~ /version ([\d\.]+),/ ) {
		Carp::croak("Failed to locate Qemu version");
	}
	$self->{qemu_version} = version->new("$1");

	# Check the qemu version
	unless ( $self->qemu_version >= version->new('0.7.0') ) {
		Carp::croak("Currently only supports qemu 0.7.0 or newer");
	}

	# Get a temporary file to build the ISO image to
	unless ( $self->injector_iso ) {
		(undef, $self->{injector_iso}) = File::Temp::tempfile( SUFFIX => '.iso' );
	}
	unless ( $self->injector_iso ) {
		Carp::croak("Failed to find or create a temporary file for the injector iso");
	}

	$self;
}

sub injector_iso {
	$_[0]->{injector_iso};
}

sub qemu_bin {
	$_[0]->{qemu_bin};	
}

sub qemu_version {
	$_[0]->{qemu_version};
}

sub qemu_pid {
	$_[0]->{qemu_pid};
}





#####################################################################
# PITA::Guest::Driver::Qemu Methods

# Execute ping/discover/test all the same way
sub qemu_execute {
	my $self = shift;

	# Launch the support server
	$self->SUPER::ping_execute(@_);

	# Launch qemu
	$self->qemu_run;

	1;
}
	
# Boot qemu and run till it shut down
sub qemu_run {
	my $self = shift;

	# Already started?
	if ( $self->qemu_pid ) {
		Carp::croak("Found existing PID. Cannot start, already running");
	}

	# Launch qemu
	unless ( $self->qemu_start ) {
		Carp::croak("Failed to launch qemu");
	}

	# Main run-loop
	### DURING DEVELOPMENT, SET A DEFAULT 1 HOUR LIMIT
	my $timeout = 3600;
	while ( $timeout-- ) {
		# Has the support server shut down.
		if ( $self->support_server->parent_pidfile ) {
			# PID file still exists, the support server
			# is still waiting for something.
			next;
		}

		# Support server has shut down.
		# So we can kill the qemu instance now.
		if ( $self->snapshot ) {
			# All changes will be discarded, kill it
			return $self->qemu_stop;
		}

		# The image ISN'T in snapshot mode, so we should
		# give it a few minutes to shut down elegantly,
		# which is what it should have started doing now
		# that it sent all the needed reports.
		# Lets give it 5 minutes. (windows can be slow)
		return $self->qemu_shutdown(300);
	}

	# It's been running for way too long, kill it
	$self->qemu_stop;	
}

sub qemu_start {
	my $self = shift;

	# Fork off the child
	$self->{qemu_pid} = fork();
	unless ( defined $self->{qemu_pid} ) {
		Carp::croak("Failed to fork off qemu child process");
	}

	# Split into parent of child side
	return $self->{qemu_pid}
		? $self->_qemu_start_parent
		: $self->_qemu_start_child;
}

sub _qemu_start_child {
	my $self = shift;

	# To avoid print anything we shouldn't, close stdout and stderr
	close STDOUT;
	close STDERR;

	# Start the qemu process
	my $cmd = $self->qemu_command;
	exec @$cmd;
	exit(0);
}

sub _qemu_start_parent {
	my $self = shift;

	# Pause for a second to make sure the exec is triggered ok
	sleep 1;

	# If everything went ok, it will respond to a sigzero
	if ( $self->signal_ping ) {
		# Qemu has started, done
		return 1;
	}

	# Something went wrong
	delete $self->{qemu_pid};
	return '';
}

sub qemu_shutdown {
	my $self    = shift;
	my $timeout = _POSINT(shift)
		or Carp::croak("Did not provide a shutdown period");

	# Do we think it is running?
	unless ( $self->qemu_pid ) {
		# Nope
		return 1;
	}

	# Assuming the guest OS has APC support, it should shut
	# down on it's own and the process should end after that.
	while ( $timeout-- ) {
		# Has it stopped?
		unless ( $self->signal_ping ) {
			# Yes
			delete $self->{qemu_pid};
			return 1;
		}
	}

	# It's had time to finish now.
	# If it just doesn't have APC, then stop will work cleanly
	# now. If now, it's taking WAY too long to stop... a lockup maybe?
	# Either way, time to get more serious.
	$self->qemu_stop;
}

sub qemu_stop {
	my $self = shift;

	# Do we think it is running?
	unless ( $self->qemu_pid ) {
		# Nope
		return 1;
	}

	# Is it actually running?
	unless ( $self->signal_ping ) {
		# Nope
		delete $self->{qemu_pid};
		return 1;
	}

	# Yes, it is running, so start with a SIGTERM.
	# This is equivalent to suddenly killing power to the internal
	# operating system, but allowing the emulator itself time
	# to clean up, sync the image files properly, remove temporary
	# files, and so on.
	unless ( $self->signal_term ) {
		# We COULD send a ping, but we couldn't send a term. Weird.
		# Warn and continue. In the case of a race condition,
		# we won't be able to ping it anyway in a moment, and will
		# consider it a success.
		warn "Unexpectedly failed to send SIGTERM to qemu";
	}

	# Give qemu 15 seconds to shut down elegantly
	while ( 1 .. 15 ) {
		sleep 1;
		next if $self->signal_ping;

		# Can't signal any more, it has shut down.
		delete $self->{qemu_pid};
		return 1;
	}

	# Failed to shut down after 15 seconds
	$self->signal_kill;
	sleep 1;
	if ( $self->signal_ping ) {
		# Just won't listen to us...
		Carp::croak("Failed to kill qemu process with SIGTERM or SIGKILL");
	}

	delete $self->{qemu_pid};
	return 1;
}

# Generate the basic qemu launch command
sub qemu_command {
	my $self = shift;
	my @cmd  = ( $self->qemu_bin );

	# Set the memory level
	push @cmd, '-m' => $self->memory;

	# Run in snapshot mode?
	if ( $self->snapshot ) {
		push @cmd, '-snapshot';
	}

	# Run headless
	push @cmd, '-nographic';

	# Set the main hard drive
	push @cmd, '-hda' => $self->image;

	# Set the injector directory
	push @cmd, '-cdrom' => $self->injector_iso;

	return \@cmd;
}

### NOTE: Signal numbers below are confirmed by 02_support_server.t
###       in the main PITA distribution.

sub signal_ping {
	my $self = shift;
	my $pid  = $self->qemu_pid
		or Carp::croak("No process PID to signal_ping");
	kill( 0 => $pid );
}

sub signal_term {
	my $self = shift;
	my $pid  = $self->qemu_pid
		or Carp::croak("No process PID to signal_term");
	kill( 15 => $pid );	
}

sub signal_kill {
	my $self = shift;
	my $pid  = $self->qemu_pid
		or Carp::croak("No process PID to signal_kill");
	kill( 9 => $pid );
}





#####################################################################
# PITA::Guest::Driver::Image Methods

# Qemu uses a standard networking setup
sub support_server_addr {
	$_[0]->support_server
		? shift->SUPER::support_server_addr
		: '127.0.0.1';
}

sub support_server_uri {
	URI->new( "http://10.0.2.2:51234/" );
}

# Build the injector directory as normal,
# then compile into an ISO image.
sub prepare_task {
	my $self = shift;
	$self->SUPER::prepare_task(@_);

	# Use Filesys::MakeISO to build the ISO file
	my $mkisofs = Filesys::MakeISO->new;
	$mkisofs->dir($self->injector_dir);
	$mkisofs->image($self->injector_iso);
	$mkisofs->joliet(1);
	$mkisofs->rock_ridge(1);
	unless ( $mkisofs->make_iso ) {
		Carp::croak("Failed to create injector ISO image");
	}

	1;
}

# When we clean the injectors, truncate (but don't delete) the iso file
sub clean_injector {
	my $self = shift;
	$self->SUPER::clean_injector(@_);

	# Truncate the iso file
	unless ( open( ISO, '>', $self->injector_iso ) ) {
		Carp::croak("Failed to truncate injector_iso file");
	}
	unless ( print ISO '' ) {
		Carp::croak("Failed to truncate injector_iso file");
	}
	unless ( close ISO ) {
		Carp::croak("Failed to truncate injector_iso file");
	}

	1;
}





#####################################################################
# PITA::Guest::Driver Methods

# Redirect to the main execution
sub ping_execute {
	shift->qemu_execute(@_);
}

# Redirect to the main execution
sub discover_execute {
	shift->qemu_execute(@_);
}

# Redirect to the main execution
sub test_execute {
	shift->qemu_execute(@_);
}





#####################################################################
# PITA::Guest::Driver Methods

sub DESTROY {
	$_[0]->SUPER::DESTROY();
	if ( $_[0]->{injector_iso} and -f $_[0]->{injector_iso} ) {
		File::Remove::remove( $_[0]->{injector_iso} );
	}
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Host-Driver-Qemu>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2005 - 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
