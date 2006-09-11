package POE::Declare::Object;

=pod

=head1 NAME

POE::Thing - A POE abstraction layer for conciseness and simplicity

=head1 DESCRIPTION

L<POE> is a very powerful and flexible system for doing asynchronous
programming.

But personally, I find it confusing and tricky to use at times.

It is flexible to the point of having too much choice, has a terminology
that is sometimes confusing, a tendency towards very verbose programming,
and POE components aren't as easy to reuse as I would like.

To be fair, a lot of these issues are done for the sake of speed,
dependency minimisation and Perl version compatibility, but sometimes speed
doesn't matter so much, you can be sure of a modern Perl version, and you
are more interested in expressiveness and development time.

B<POE::Thing> is an abstraction layer implemented on a number of principles.

=head2 Object Orientation is Worth It

Although POE emphasises speed, for general usage the additional development
time and flexibility gained by using OO methods is worth it for most general
uses.

=head2 The Use of Modern Techniques

Techniques such as subroutines attributes can be used to make POE development
much more declarative and expressive.

These techniques, and other setup-time abstractions, can also allow us to
check the configuration of the objects and catch user mistakes early,
reducing the number of bugs, and reducing the total code size.

=head2 Early Checking

POE can be somewhat confusing about what it does or does not allow.

It is perfectly happy to let you spell an event name incorrectly, and yet
will not allow you to load POE but not run a kernel (it throws a warning
instead).

Where possible, L<POE::Thing> adds additional checking at compile time, and
at constructor time (before the POE kernel is started) to catch any mistakes
you make.

=head2 Conciseness

Using POE can lead to duplication, particular for cases like having to
specify all your event name to subroutine bindings seperately.

As part of the simplification, L<POE::Thing> tries to reduce the amount of
typing you need to do to interact with POE directly. Ideally, you should
never have to touch POE directly, and most of the nitty gritty will be
hidden away.

=head1 METHODS

=cut

use 5.008005;
use strict;
use attributes   ();
use Carp         ();
use Scalar::Util qw{ refaddr };
use Params::Util ();
use POE          qw{ Session };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# Inside-out storage of internal values
my %SESSIONID = ();





#####################################################################
# Attribute Hooks

# Only events are supported for now
sub MODIFY_CODE_ATTRIBUTES {
	my ($class, $code, $name, @params) = @_;
	unless ( $name eq 'Event' ) {
		Carp::croak("Unknown of unsupported attribute $name");
	}

	# Register an event
	POE::Declare::event( $class, $name );
	return ();
}

sub meta {
	POE::Declare::meta( ref $_[0] || $_[0] );
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Clear out any accidentally set internal values
	delete $SESSIONID{$self->refaddr};

	# Set the alias
	if ( exists $self->{Alias} ) {
		unless ( Params::Util::_STRING($self->{Alias}) ) {
			Carp::croak("Did not provide a valid Alias param, must be a string");
		}
	} else {
		$self->{Alias} = $self->meta->next_alias;
	}

	$self;
}

sub Alias {
	$_[0]->{Alias};
}

sub spawn {
	# Handle the class context
	unless ( ref $_[0] ) {
		my $class = shift;
		my $self  = $class->new( @_ );
		$self->spawn;
		return $self;
	}

	# Handle the normal object context
	my $self  = shift;

	# Create the session
	$SESSIONID{$self->refaddr} = POE::Session->create(
		heap           => $self,
		package_states => [
			$self->meta->name => $self->meta->package_states,
			],
		)->ID;

	# Return the alias
	$self->Alias;
}

sub spawned {
	!! $SESSIONID{$_[0]->refaddr};

}

sub session_id {
	$SESSIONID{$_[0]->refaddr};
}

sub session {
	my $id = $SESSIONID{$_[0]->refaddr} or return undef;
	$poe_kernel->ID_id_to_session($id)  or return undef;
}

sub kernel {
	$poe_kernel;
}





#####################################################################
# Default Events

=pod

=head2 _start

The default C<_start> implementation is used to register the alias for
the heap object with the kernel. As such, if you need to do your own
tasks in C<_start> you should always call it first.

  sub _start {
      my $self = $_[HEAP];
      shift()->SUPER::_start(@_);

      # Additional tasks here
      ...
  }

Please note though that the super call will break @_ in the current
subroutine, and so you should not use C<$_[KERNEL]> style expressions
after the SUPER call.

=cut

sub _start {
	$poe_kernel->alias_set( $_[HEAP]->Alias );
	return;
}

=pod

=head2 _stop

The default C<_stop> implementation is used to clean up our resources
and aliases in the kernel. As such, if you need to do your own
tasks in C<_stop> you should always do them first and then call the
SUPER last.

  sub _stop {
      my $self = $_[HEAP];

      # Additional tasks here
      ...

      shift()->SUPER::_stop(@_);
  }

=cut

sub _stop {
	my $self = $_[HEAP];

	# Clean up the named session.
	# (although this could well be superfluous)
	$poe_kernel->alias_remove( $self->Alias );

	# Remove the stored session ID
	delete $self->{__SESSIONID};

	return;
}






#####################################################################
# POE::Session Wrappers

=pod

=head2 ID

The C<ID> is a wrapper for the equivalent L<POE::Session> method, and
returns the id number for the L<POE::Session>.

Returns an integer, or C<undef> if the heap object has not spawned.

=cut

sub ID {
	$SESSIONID{$_[0]->refaddr}
}

=pod

=head2 postback

  my $handler = $object->postback( 'event_name', $first_param, 'second_param' );
  $handler->( $third_param, $first_param );

The C<postback> method is a wrapper for the equivalent L<POE::Session>
method, and creates an anonymous subroutine that triggers a C<post> for
a named event of the heap object.

Returns a C<CODE> reference, or dies if the heap object has not been
spawned.

=cut

sub postback {
	shift->session->postback( @_ );
}

=pod

=head2 callback

  my $handler = $object->callback( 'event_name', $first_param, 'second_param' );
  $handler->( $third_param, $first_param );

The C<callback> method is a wrapper for the equivalent L<POE::Session>
method, and creates an anonymous subroutine that triggers a C<post> for
a named event of the heap object.

Please don't confuse this for a method relating to "callback events"
mentioned earlier, it is not related to them.

Returns a C<CODE> reference, or dies if the heap object has not been
spawned.

=cut

sub callback {
	shift->session->callback( @_ );
}

=pod

=head2 lookback

  sub create_foo {
      my $self  = shift;
      my $thing = Other::Class->new(
           ConnectEvent => $self->lookback('it_connected'),
           ConnectError => $self->lookback('it_failed'),
           );
  
      ...
  }

The C<lookback> method is a safe alias for C< [ $self->Alias, 'event_name' ] >.

When creating the lookback, the name will be double checked to verify that
the handler actually exists and is registered.

Returns a reference to an C<ARRAY> containing the heap object's alias and
the event name.

=cut

sub lookback {
	my $self  = shift;
	my $class = ref $self;
	my $name  = _IDENTIFIER($_[0])
		or Carp::croak("Invalid identifier name '$_[0]'");

	# Does the method exist?
	unless ( $self->can($name) ) {
		Carp::croak( ref($self) . " has no method '$name'" );
	}

	# Is it an event
	unless ( grep { $_ eq $name } $self->meta->package_states ) {
		Carp::croak( "$class does not have the event '$name'" );
	}

	return [ $self->Alias, $name ];
}




#####################################################################
# POE::Kernel Wrappers

=pod

=head2 post

The C<post> method runs a POE kernel C<post> for a named event for the
heap object's session.

Returns void.

=cut

sub post {
	$poe_kernel->post( shift->Alias, @_ );
}

=pod

=head2 call

The C<call> method runs a POE kernel C<call> for a named event for the
heap object's session.

Returns as for the particular event handler, but generally returns void.

=cut

sub call {
	$poe_kernel->call( shift->Alias, @_ );
}

### Wrapper for the (new) POE timer API

=pod

=head2 alarm_set

The C<alarm_set> method is equivalent to the L<POE::Kernel> method
of the same name, setting an alarm for a named event of the heap object's
session.

=cut

sub alarm_set {
	my $self = shift;
	$poe_kernel->alarm_set( @_ );
}

=pod

=head2 alarm_adjust

The C<alarm_adjust> method is equivalent to the L<POE::Kernel> method
of the same name, adjusting an alarm for a named event of the heap
object's session.

=cut

sub alarm_adjust {
	my $self = shift;
	$poe_kernel->alarm_adjust( @_ );
}

=pod

=head2 alarm_remove

The C<alarm_remove> method is equivalent to the L<POE::Kernel> method
of the same name, removing an alarm for a named event of the heap
object's session.

=cut

sub alarm_remove {
	my $self = shift;
	$poe_kernel->alarm_remove( @_ );
}

=pod

=head2 alarm_clear

The C<alarm_clear> method is a convenience method. It takes the name of
a hash key for the object, containing a timer id. If the ID is set, it
is cleared. If not, the method shortcuts.

=cut

sub alarm_clear {
	$_[0]->{$_[1]} or return 1;
 	$_[0]->alarm_remove(delete $_[0]->{$_[1]});
}

=pod

=head2  delay_set

The C<delay_set> method is equivalent to the L<POE::Kernel> method
of the same name, setting a delayed alarm for a named event of the
heap object's session.

=cut

sub delay_set {
	my $self = shift;
	$poe_kernel->delay_set( @_ );
}

=pod

=head2  delay_adjust

The C<delay_adjust> method is equivalent to the L<POE::Kernel> method
of the same name, adjusting a delayed alarm for a named event of the
heap object's session.

=cut

sub delay_adjust {
	my $self = shift;
	$poe_kernel->delay_adjust( @_ );
}





#####################################################################
# message Support

# Dispatch a message, if registered
sub send_message {
	my ($self, $name) = @_;
	return unless $self->{$name};
	return $self->{$name}->( $self->Alias, @_ );
}

=pod

=head2 set_message

The C<set_message> method is used to set or change a callback event
registration after the initial creation of the object.

=cut

sub set_message {
	my $self = shift;
	my $name  = shift;
	unless ( $self->{__callback}->{$name} ) {
		Carp::croak("The callback event $name does not exist");
	}
	$self->{$name} = _CALLBACK(shift);
	return 1;
}

# Check the validity of a provided message handler,
# dying if not valid.
sub is_message {
	my $self = shift;
	my $it   = shift;

	# The callback is an anonymous subroutine
	return $it if Params::Util::_CODE($it);

	# Otherwise, we also allow a reference to an array,
	# which contains two identifiers (like foo_bar).
	# This will be converted to a call to the relevant
	# POE session.event
	if (
		    Params::Util::_ARRAY0($it)
		and scalar(@$it) == 2
		and Params::Util::_IDENTIFIER($it->[0])
		and Params::Util::_IDENTIFIER($it->[1])
	) {
		# Create a closure for the call
		my $session = $it->[0];
		my $event   = $it->[1];
		my $closure = sub {
			$poe_kernel->call( $session, $event, @_ );
			};
		return $closure;
	}

	# Otherwise, not valid
	Carp::croak('Invalid callback event handler');
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Twin>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<lt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
