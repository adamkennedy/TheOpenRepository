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
use     vars              qw( $VERSION                                 );
use     Object::InsideOut qw( Perl::Dist::WiX::Base::Fragment Storable );
use     Carp              qw( croak                                    );
use     Params::Util      qw( _IDENTIFIER _STRING                      );
require Perl::Dist::WiX::Registry::Key;
require Perl::Dist::WiX::Registry::Entry;

use version; $VERSION = qv('0.13_04');

#>>>
#####################################################################
# Accessors:

#####################################################################
# Constructor for Registry
#
# Parameters: [pairs]
#   id, directory: See Base::Fragment

sub _pre_init : PreInit {
	my ( $self, $args ) = @_;

	# Apply defaults
	$args->{id} ||= 'Registry';

	return;
}

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
	my $count = scalar @{ $self->get_components };

	return undef if ( 0 == $count );

	foreach my $i ( 0 .. $count - 1 ) {
		$id = $self->get_components->[$i]->get_component_id;
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
		PDWiX->throw('Missing or invalid id');
	}
	unless ( _STRING( $params{key} ) ) {
		PDWiX->throw('Missing or invalid key');
	}

	# Set defaults.
	unless ( _STRING( $params{root} ) ) {
		$params{root} = 'HKLM';
	}

	# Search for a key...
	my $key   = undef;
	my $count = scalar @{ $self->get_components };
	foreach my $i ( 0 .. $count - 1 ) {
		if ( $self->get_components->[$i]
			->is_key( $params{root}, $params{key} ) )
		{
			$key = $self->get_components->[$i];
			last;
		}
	}

	# Create a key if we don't have one already.
	if ( not defined $key ) {
		$key = Perl::Dist::WiX::Registry::Key->new(
			id   => $params{id},
			root => $params{root},
			key  => $params{key},
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
