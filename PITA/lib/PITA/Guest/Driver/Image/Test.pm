package PITA::Guest::Driver::Image::Test;

use 5.005;
use strict;
use base 'PITA::Guest::Driver::Image';
use PITA::Image ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.22';
}





#####################################################################
# PITA::Guest::Driver Methods

sub ping_execute {
	my $self = shift;

	# Launch the support server
	$self->SUPER::ping_execute(@_);

	# The Support Server SHOULD be running
	# Save some information from it.
	$self->{_test}->{ss_pidfile} =    $self->support_server->parent_pidfile;
	$self->{_test}->{ss_started} = -f $self->support_server->parent_pidfile;

	# Skip the main function if it didn't start
	if ( $self->{_test}->{ss_started} ) {
		# Create the image manager.
		# This should result in the GET / ping request being sent
		my $image_manager = $self->_image_manager;
		$self->{_test}->{im_run} = $image_manager->run;
	}

	# The Support Server, having gotten the initial GET /
	# should now have stoppped on it's own.
	$self->{_test}->{ss_stopped} = ! -f $self->{_test}->{ss_pidfile};

	1;
}

# Do the normal preparation and take over at execution
sub discover_execute {
	my $self = shift;

	# Launch the support server
	$self->SUPER::discover_execute(@_);

	# The Support Server SHOULD be running
	# Save some information from it.
	$self->{_test}->{ss_pidfile} =    $self->support_server->parent_pidfile;
	$self->{_test}->{ss_started} = -f $self->support_server->parent_pidfile;

	# Skip the main function if it didn't start
	if ( $self->{_test}->{ss_started} ) {
		# Create the image manager.
		# This should result in the GET / ping request being sent
		my $image_manager = $self->_image_manager;
		$self->{_test}->{im_run}    = $image_manager->run;
		$self->{_test}->{im_report} = $image_manager->report;
	}

	# The Support Server, having gotten the initial GET /
	# plus any task reports, and so should be shutting-down.
	# Give it a second to finalize it's business.
	sleep 1;
	$self->{_test}->{ss_stopped} = ! -f $self->{_test}->{ss_pidfile};

	1;
}

sub test_execute {
	my $self = shift;

	# Launch the support server
	$self->SUPER::test_execute(@_);

	# The Support Server SHOULD be running
	# Save some information from it.
	$self->{_test}->{ss_pidfile} =    $self->support_server->parent_pidfile;
	$self->{_test}->{ss_started} = -f $self->support_server->parent_pidfile;

	# Skip the main function if it didn't start
	if ( $self->{_test}->{ss_started} ) {
		# Create the image manager.
		# This should result in the GET / ping request being sent
		my $image_manager = $self->_image_manager;
		$self->{_test}->{im_run}    = $image_manager->run;
		$self->{_test}->{im_report} = $image_manager->report;
	}

	# The Support Server, having gotten the initial GET /
	# should now have stoppped on it's own.
	$self->{_test}->{ss_stopped} = ! -f $self->{_test}->{ss_pidfile};

	1;
}





#####################################################################
# Support Methods

sub _image_manager {
	my $self    = shift;
	my $manager = PITA::Image->new(
		injector => $self->injector_dir,
		cleanup  => 1,
		);

	# For platforms, we support the current Perl only
	$manager->add_platform(
		scheme => 'perl5',
		path   => $^X, # Only works on Unix
		);

	$manager;
}

1;
