package POE::Declare::Object;

=pod

=head1 NAME

POE::Declare::Object - Base object for POE::Declare classes

=head1 DESCRIPTION

L<POE::Declare::Object> provides the base package that delivers the core
functionality for all instantiated L<POE::Declare> objects.

Functionality and methods defined here are available in all L<POE::Declare>
objects.

=head1 METHODS

=cut

use 5.008007;
use strict;
use attributes   ();
use Carp         ();
use Scalar::Util ();
use Params::Util ();
use POE          qw{ Session };
use POE::Declare ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}

# Inside-out storage of internal values
my %SESSIONID = ();

# Set default attributes
POE::Declare::declare( Alias => 'Param' );





#####################################################################
# Attribute Hooks

# Only events are supported for now
sub MODIFY_CODE_ATTRIBUTES {
	my ($class, $code, $name, @params) = @_;

	# Register an event
	if ( $name eq 'Event' ) {
		# Add to the coderef event register
		$POE::Declare::EVENT{Scalar::Util::refaddr($code)} = [
			'POE::Declare::Meta::Event',
		];
		return ();
	}

	# Register a timeout
	if ( $name =~ /^Timeout\b/ ) {
		unless ( $name =~ /^Timeout\((.+)\)$/ ) {
			Carp::croak("Missing or invalid timeout");
		}
		my $delay = $1;
		unless ( Params::Util::_POSINT($delay) ) {
			Carp::croak("Missing or invalid timeout");
		}
		$POE::Declare::EVENT{Scalar::Util::refaddr($code)} = [
			'POE::Declare::Meta::Timeout',
			default => $delay,
		];
		return ();
	}

	# Unknown method type
	Carp::croak("Unknown or unsupported attribute $name");
}

=pod

=head2 meta

The C<meta> method can be run on either a class or instances of that class,
and returns the L<POE::Declare::Meta> metadata object for that class.

=cut

sub meta {
	POE::Declare::meta( ref $_[0] || $_[0] );
}





#####################################################################
# Constructor

=pod

=head2 new

  # Create an object, but do not spawn it
  my $object = My::Class->new(
      Param1 => 'value',
      Param2 => 'value',
  );

The C<new> constructor is used to create a L<POE::Declare> component
B<WITHOUT> immediately starting it up.

This is typically assemble to build heirachies of interlinked
components and services, without the need to start all of them
simultaneously.

Instead, a startup routine in the top object of the heirachy can
undertake a controlled startup process, bootstrapping each piece of
the overall application.

All constructors take a series of named params and return a new instance,
or throw an exception on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Clear out any accidentally set internal values
	delete $SESSIONID{Scalar::Util::refaddr($self)};

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

=pod

=head2 Alias

The C<Alias> method returns the L<POE::Session> alias that will be used with
this object instance.

These will typically be of the form C<'My::Class.123'> but may be a different
value if a custom C<Alias> param has been explicitly passed to the constructor.

=cut

# This is auto-generated
# sub Alias {
#     $_[0]->{Alias};
# }

=pod

=head2 spawn

  # Spawn (i.e. startup) an existing object
  $object->spawn;
  
  # Create the start the object in one call
  my $alias = My::Class->spawn(
      Param1 => 'value',
      Param2 => 'value',
  );

The C<spawn> method is used to create the L<POE::Session> for this object.

It returns the session alias as a convenience, or throws an exception on error.

When called on the class instead of an object, it provides a shortcut method
for a one-shot construction and spawning of an object, returning the object
instead of the session alias.

Throws an exception on error.

=cut

sub spawn {
	# Handle the class context
	unless ( ref $_[0] ) {
		my $class = shift;
		my $self  = $class->new( @_ );
		$self->spawn;
		return $self;
	}

	# Create the session
	my $self = shift;
	my $meta = $self->meta;
	$SESSIONID{Scalar::Util::refaddr($self)} = POE::Session->create(
		heap           => $self,
		package_states => [
			$meta->name => [ $meta->package_states ],
		],
	)->ID;

	# Return the alias
	$self->Alias;
}

=pod

=head2 spawned

The C<spawned> method returns true if the L<POE::Session> for a B<POE::Declare>
object has been created, or false if not.

=cut

sub spawned {
	!! $SESSIONID{Scalar::Util::refaddr($_[0])};

}

=pod

=head2 session_id

The C<session_id> accessor finds and returns the internal L<POE::Session>
id for this instance, or C<undef> if the object has not been spawned.

=cut

sub session_id {
	$SESSIONID{Scalar::Util::refaddr($_[0])};
}

=pod

=head2 session_id

The C<session_id> accessor finds and returns the internal L<POE::Session>
object for this instance, or C<undef> if the object has not been spawned.

=cut

sub session {
	my $id = $SESSIONID{Scalar::Util::refaddr($_[0])} or return undef;
	$poe_kernel->ID_id_to_session($id)                or return undef;
}

=pod

=head2 kernel

The C<kernel> method is provided as a convenience. It returns the
L<POE::Kernel> object that objects of this class will run in.

=cut

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
      shift->SUPER::_start(@_);

      # Additional tasks here
      ...
  }

Please note though that the super call will break @_ in the current
subroutine, and so you should not use C<$_[KERNEL]> style expressions
after the SUPER call.

=cut

sub _start : Event {
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

      shift->SUPER::_stop(@_);
  }

=cut

sub _stop : Event {
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
	$SESSIONID{Scalar::Util::refaddr($_[0])};
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
		and
		scalar(@$it) == 2
		and
		Params::Util::_IDENTIFIER($it->[0])
		and
		Params::Util::_IDENTIFIER($it->[1])
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





#####################################################################
# Compile the POE::Declare form of POE::Declare::Object itself

POE::Declare::compile();

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
