package PITA::XML::Guest;

=pod

=head1 NAME

PITA::XML::Guest - A testing environment, typically a system image

=head1 SYNOPSIS

  # A simple guest using the local Perl
  # (mostly used for test purposes)
  my $dist = PITA::XML::Guest->new(
  	driver => 'Local',
	params => {},
  	);

=head1 DESCRIPTION

C<PITA::XML::Guest> is an object for holding information about
a testing guest environment. A PITA Guest is a container with specific
operating system and hardware that contains one or more testing contexts,
represented in L<PITA::XML> by L<PITA::XML::Platform> objects.

=head1 METHODS

=cut

use strict;
use base 'PITA::XML::Storable';
use Carp             ();
use Class::Inspector ();
use Params::Util     '_INSTANCE',
                     '_STRING',
                     '_CLASS',
                     '_HASH0',
                     '_SET0';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.30';
}

sub xml_entity { 'guest' }





#####################################################################
# Constructor and Accessors

my %ALLOWED = (
	driver   => 1,
	config   => 1,
	);

=pod

=head2 new

  # The most correct way to specify a guest
  my $guest1 = PITA::XML::Guest->new(
      driver => 'Qemu',
      config => {
          memory   => 256,
          snapshot => 1,
      }
  );
  
  # Equivalent, using shorthand.
  # Anything other that 'driver' is considered a config entry.
  my $guest = PITA::XML::Guest->new(
      driver   => 'Qemu',
      memory   => 256,
      snapshot => 1,
      );

The C<new> constructor creates a new E<lt>guestE<gt> element.

It has a single compulsory parameter of the guest driver name, and takes
optionally a set of named params to provide as creation params for the
guest driver object.

Returns a new L<PITA::XML::Guest> or throw an exception on error.

=cut

sub new {
	my $class  = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Move the non-core options into the config hash
	unless ( _HASH0($self->{config}) ) {
		$self->{config} = {};
	}
	foreach my $k ( sort keys %$self ) {
		next if $ALLOWED{$k};
		$self->{config}->{$k} = delete $self->{$k};
	}

	# Check the object
	$self->_init;

	$self;
}

=pod

=head2 read

  $guest = PITA::XML::Guest->new( 'guest.xml' );

The C<read> constructor loads a guest from an existing L<PITA::XML> file.

Returns a new L<PITA::XML::Guest> object, or throws an exception on error.

=cut

sub read {
	my $class = shift;
	my $fh    = PITA::XML->_FH(shift);

	### NOTE: DISABLED TILL WE FINALIZE THE SCHEMA
	# Validate the document and reset the handle
	# $class->validate( $fh );
	# $fh->seek( 0, 0 ) or Carp::croak(
	#	'Failed to reset file after validation (seek to 0)'
	#	);

	# Build the object from the file and validate
	my $self = bless { config => {} }, $class;
	my $parser = XML::SAX::ParserFactory->parser(
		Handler => PITA::XML::SAXParser->new($self),
		);
        $parser->parse_file($fh);

	$self;
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# Requires a driver
	unless ( _CLASS($self->driver) ) {
		Carp::croak('Missing or invalid driver');
	}

	# Check the configuration hash
	unless ( _HASH0($self->config) ) {
		Carp::croak('Invalid, missing, or empty config');
	}

	# Optional files
	$self->{files} ||= [];
	unless ( _SET0($self->{files}, 'PITA::XML::File') ) {
		Carp::croak('Invalid files');
	}

	# Optional platforms
	$self->{platforms} ||= [];
	unless ( _SET0($self->{platforms}, 'PITA::XML::Platform') ) {
		Carp::croak('Invalid platforms');
	}

	$self;
}

=pod

=head2 driver

The C<driver> accessor returns the shorthand name of the driver, as it
is stored in the PITA-XML xml file.

For example, if the guest uses the L<PITA::Guest::Driver::Qemu> driver,
the C<driver> method return C<'Qemu'>.

=cut

sub driver {
	$_[0]->{driver};
}

=pod

=head2 driver_available

The C<driver_available> method will check your local system to see if the
driver for this guest is available in the current Perl environment.

Returns true if the driver is available, or false if not.

=cut

sub driver_available {
	my $self   = shift;
	my $driver = 'PITA::Guest::' . $self->driver;
	Class::Inspector->available( $driver );
}

=pod

=head2 config

The C<config> accessor returns the configuration for the driver.

This configuration is entirely driver-specific, and although conventions
may exist, you should not rely on the contents of the configuration to
have any specific meaning.

Returns a reference to a C<HASH> containing plain scalar keys and values.

=cut

sub config {
	$_[0]->{config};
}

=pod

=head2 files

Each guest will require zero or more file resources. In most cases, this
consists of drive images or emulator configuration files.

The C<files> method returns all existing files for this guest.

Returns a list of L<PITA::XML::File> objects

=cut

sub files {
	@{ $_[0]->{files} };
}

=pod

=head2 platforms

Each guest should contain one or more testing contexts, where packages
of some specific type can be automatically tested. In PITA parlance, a
scheme-specific testing context is known as a I<Platform>.

The C<platforms> method returns all existing known platforms for this
guest.

Returns a list of one of more L<PITA::XML::Platform> objects.

If this method returns a zero-length list, then the guest may be
unprocessed, and has not been 'discovered' yet.

=cut

sub platforms {
	@{ $_[0]->{platforms} };
}

=pod

=head2 add_file

The C<add_file> method adds a new driver-specific file to
the guest.

It takes as it's only parameter a L<PITA::XML::File> object.

Returns true if added, or throws an exception if not passed a valid
L<PITA::XML::File> object.

=cut

sub add_file {
	my $self = shift;
	my $file = _INSTANCE(shift, 'PITA::XML::File')
		or Carp::croak('Did not provide a PITA::XML::File object');

	# Add it to the array
	$self->{files} ||= [];
	push @{$self->{files}}, $file;

	1;
}

=pod

=head2 add_platform

The C<add_platform> method adds a new testing context to the guest.

In general, you should B<not> be manually adding platform definitions
to the guest unless you are implementing a driver auto-discovery
mechanism for your new or custom L<PITA::Guest::Driver> class.

That is, the PITA driver system itself will take you unprocessed guest,
load it, query the guest for its platform list, and update the XML file
independantly, without the help of any external system.

It takes as it's only parameter a L<PITA::XML::Platform> object.

Returns true if added, or throws an exception if not passed a valid
L<PITA::XML::File> object.

=cut

sub add_platform {
	my $self     = shift;
	my $platform = _INSTANCE(shift, 'PITA::XML::Platform')
		or Carp::croak('Did not provide a PITA::XML::Platform object');

	# Add it to the array
	$self->{platforms} ||= [];
	push @{$self->{platforms}}, $platform;

	1;
}





#####################################################################
# Main Methods

=pod

=head2 discovered

The C<discovered> method is a convenience method, and checks to see if
platform discovery has been done on the guest, or if it is unprocessed.

Returns true if the platforms have been discovered, or false if not.

=cut

sub discovered {
	!! $_[0]->platforms;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-XML>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::XML>

The Perl Image Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
