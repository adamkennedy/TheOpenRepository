package POE::Declare::Meta::Timeout;

=pod

=head1 NAME

POE::Declare::Meta::Timeout - A named timeout with generated support methods

=head1 SYNOPSIS

  # Send a request
  sub request : Event {
      $_[SELF]->request_timeout_start;
      $_[SELF]->{handle}->put('something');
  }
  
  # Recieved a response
  sub response : Event {
      if ( $_[ARG0] eq 'keepalive' ) {
          $_[SELF]->request_timeout_restart;
          return;
      }

      $_[SELF]->request_timeout_stop;
      $_[SELF]->{parent}->post('child_response', $_[ARG0]);
  }
  
  # Did not get a response
  sub request_timeout : Timeout(30) {
      # Take some action
      $_[SELF]->cleanup;
      $_[SELF]->{parent}->post('child_response', 'timeout');
  }

=head1 DESCRIPTION

B<POE::Declare::Meta::Timeout> is a sub-class of C<Event> with access to
a number of additional methods relating to timers and alarms.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Event ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.25';
	@ISA     = 'POE::Declare::Meta::Event';
}

use Class::XSAccessor {
	getters => {
		delay => 'delay',
	},
};





#####################################################################
# Main Methods

sub _compile {
	my $name  = $_[0]->{name};
	my $delay = $_[0]->{delay};
	return <<"END_PERL";
sub ${name}_start {
	my \$self = (\@_ == 1) ? \$_[0] : \$_[HEAP];
	if ( \$self->{$name} ) {
		# Clear any existing timer
		\$self->${name}_clear;
	}
	my \$timer = \$poe_kernel->delay_set(
		$name => $delay
	);
	if ( \$timer ) {
		\$self->{$name} = \$timer;
		return 1;
	}

	# Invalid timer creation
	die('${name}_start provided invalid params to delay_set');	
}

sub ${name}_restart {
	my \$self = (\@_ == 1) ? \$_[0] : \$_[HEAP];
	if ( \$self->{$name} ) {
		# Have an existing timer id, try to reset it
		my \$rv = \$poe_kernel->delay_adjust(
			$name => $delay
		);
		return 1 if \$rv;
		if ( \$! == Errno::ESRCH ) {
			# Previous keepalive expired and dispatched
			delete \$self->{$name};
		} elsif ( \$! == Errno::EPERM ) {
			# Set in wrong context
			Carp::croak('Tried to reset $name timeout in bad context');
		} else {
			# Something else
			die('${name}_keepalive provided invalid params to delay_adjust');
		}
	}

	# No existing timer, create a new one
	my \$timer = \$poe_kernel->delay_set(
		$name => $delay
	);
	if ( \$timer ) {
		# Timer was set correctly
		\$self->{$name} = \$timer;
		return;
	}

	# Invalid timer creation
	die('${name}_keepalive provided invalid params to delay_set');
}

sub ${name}_stop {
	my \$self  = (\@_ == 1) ? \$_[0] : \$_[HEAP];
	my \$timer = \$self->{$name} or return;
	\$poe_kernel->alarm_remove(
		delete \$self->{$name}
	);
	return 1;
}
END_PERL
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
