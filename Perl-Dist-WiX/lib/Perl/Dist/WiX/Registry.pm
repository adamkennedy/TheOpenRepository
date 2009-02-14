package Perl::Dist::WiX::Registry;

#####################################################################
# Perl::Dist::WiX::Registry - A <Fragment> and <DirectoryRef> tag that
# contains <RegistryKey>s and <RegistryValue>s.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.006;
use     strict;
use     warnings;
use     Carp             qw( croak               );
use     Params::Util     qw( _IDENTIFIER _STRING );
require Perl::Dist::WiX::Registry::Key;
require Perl::Dist::WiX::Registry::Entry;

use vars qw( $VERSION );
use version; $VERSION = qv('0.13_02');
use base 'Perl::Dist::WiX::Base::Fragment';
#>>>
#####################################################################
# Accessors:
#   sitename: Returns the sitename parameter passed in to new.

use Object::Tiny qw{
  sitename
};


#####################################################################
# Constructor for Registry
#
# Parameters: [pairs]
#   id, directory: See Base::Fragment
#   sitename: The name of the site that is hosting the download.

sub new {
	my ( $class, %params ) = @_;

	# Apply defaults and check parameters
	unless ( defined $params{id} ) {
		$params{id} = 'Registry';
	}
	unless ( _STRING( $params{sitename} ) ) {
		croak('Missing or invalid sitename');
	}

	my $self = $class->SUPER::new(%params);

	return $self;
} ## end sub new

#####################################################################
# Main Methods

sub search_file {
	return undef;
}

sub check_duplicates {
	return undef;
}

########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   Array of Ids attached to the contained components.

sub get_component_array {
	my $self = shift;

	# Define variables.
	my @answer;
	my $id;

	# Get the array for each descendant.
	my $count = scalar @{ $self->{components} };

	return undef if ( 0 == $count );

	foreach my $i ( 0 .. $count - 1 ) {
		$id = $self->{components}->[$i]->id;
		push @answer, "C_$id";
	}

	return @answer;
} ## end sub get_component_array

########################################
# add_key
# Parameters: [pairs in hashref]
#   id, key, root: See Registry::Key->new
#   name, value, action, value_type: See Registry::Entry->entry
# Returns:
#   Object being acted upon (chainable).
# Action:
#   Creates a registry key entry.

sub add_key {
	my ( $self, %params ) = @_;

	# Check parameters.
	unless ( _IDENTIFIER( $params{id} ) ) {
		croak('Missing or invalid id');
	}
	unless ( _STRING( $params{key} ) ) {
		croak('Missing or invalid key');
	}

	# Set defaults.
	unless ( _STRING( $params{root} ) ) {
		$params{root} = 'HKLM';
	}

	# Search for a key...
	my $key   = undef;
	my $count = scalar @{ $self->{components} };
	foreach my $i ( 0 .. $count - 1 ) {
		if ($self->{components}->[$i]->is_key( $params{root}, $params{key} )
		  )
		{
			$key = $self->{components}->[$i];
			last;
		}
	}

	# Create a key if we don't have one already.
	if ( not defined $key ) {
		$key = Perl::Dist::WiX::Registry::Key->new(
			id       => $params{id},
			root     => $params{root},
			key      => $params{key},
			sitename => $self->sitename
		);
		$self->add_component($key);
	}

	# Add the entry to our key.
	$key->add_entry(
		Perl::Dist::WiX::Registry::Entry->entry(
			@params{ 'name', 'value', 'action', 'value_type' } ) );

	return $self;
} ## end sub add_key

1;
