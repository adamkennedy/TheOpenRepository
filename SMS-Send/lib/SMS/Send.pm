package SMS::Send;

=pod

=head1 NAME

SMS::Send - Driver-based API for sending SMS messages

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

SMS::Send is intended to provide a driver-based single API for sending SMS
and MMS messages. The intent is to provide a single API against which to
write the code to send an SMS message.

At the same time, the intent is to remove the limits of some of the previous
attempts at this sort of API, like "must be free internet-based SMS services".

SMS::Send drivers are installed seperately, and might use the web, email or
physical SMS hardware. It could be a free or paid. The details shouldn't
matter.

You should not have to care how it is actually sent, only that it has been
sent (although some drivers may not be able to provide certainty).

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp              ();
use Params::Util      '_HASH',
                      '_CLASS',
                      '_INSTANCE';
use SMS::Send::Driver ();

# We are a type of Adapter
use Class::Adapter::Builder
	AUTOLOAD => 'PUBLIC';

# We need plugin support to find the drivers
use Module::Pluggable
	require     => 0,
	inner       => 0,
	search_path => [ 'SMS::Send' ],
	except      => [ 'SMS::Send::Driver' ],
	sub_name    => '_installed_drivers';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# Private driver cache
my @DRIVERS = ();

=pod

=head2 installed_drivers

The C<installed_drivers> the list of SMS::Send drivers that are installed
on the current system.

=cut

sub installed_drivers {
	my $class = shift;

	unless ( @DRIVERS ) {
		my @rawlist = $class->_installed_drivers;
		foreach my $d ( @rawlist ) {
			$d =~ s/^SMS::Send:://;
		}
		@DRIVERS = @rawlist;
	}

	return @DRIVERS;
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;
	my $driver = $class->_DRIVER(shift);
	my $params = _HASH($_[0]) || { @_ };

	# Create the driver and verify
	my $object = $driver->new( %$params );
	unless ( _INSTANCE($object, 'SMS::Send::Driver') ) {
		Carp::croak("Driver Error: $driver->new did not return a driver object");
	}

	# Hand off to create our object
	my $self = $class->SUPER::new( $object );
	unless ( _INSTANCE($self, $class) ) {
		die "Internal Error: Failed to create a $class object";
	}

	return $self;
}





#####################################################################
# Support Methods

sub _DRIVER {
	my $class  = shift;

	# The driver should be a string (other than 'Driver')
	my $driver = $_[0];
	unless ( defined $driver and ! ref $driver and length $driver ) {
		Carp::croak("Did not provide a SMS::Send driver name");
	}

	# Clean up the driver name
	$driver = "SMS::Send::$driver";
	unless ( Params::Util::_CLASS($driver) ) {
		Carp::croak("Not a valid SMS::Send driver name");
	}

	# Load the driver
	eval "require $driver;";
	if ( $@ and $@ =~ /^Can't locate / ) {
		# Driver does not exist
		Carp::croak("SMS::Send driver $_[0] does not exist, or is not installed");
	} elsif ( $@ ) {
		# Fatal error within the driver itself
		# Pass on without change
		Carp::croak( $@ );
	}

	# Verify that the class is actually a driver
	unless ( $driver->isa('SMS::Send::Driver') and $driver ne 'SMS::Send::Driver' ) {
		Carp::croak("$driver is not a subclass of SMS::Send::Driver");
	}

	return $driver;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
