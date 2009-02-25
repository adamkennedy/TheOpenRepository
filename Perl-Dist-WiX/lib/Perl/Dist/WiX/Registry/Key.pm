package Perl::Dist::WiX::Registry::Key;

#####################################################################
# Perl::Dist::WiX::Registry::Key - Class for <RegistryKey> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.006;
use     strict;
use     warnings;
use     vars               qw( $VERSION                         );
use     Object::InsideOut  qw(
    Perl::Dist::WiX::Base::Component
    Storable
);
use     Readonly           qw( Readonly                         );
use     Params::Util       qw( _IDENTIFIER _STRING              );
require Perl::Dist::WiX::Registry::Entry;

use     version; $VERSION = qv('0.14');

# Defining at this level so it does not need recreated every time.
Readonly my @ROOT_OPTIONS => qw(HKMU HKCR HKCU HKLM HKU);

#>>>
#####################################################################
# Accessors:
#   none.
# Attributes:

my @root : Field : Arg(Name => 'root', Required => 1);
my @key : Field : Arg(Name => 'key', Required => 1);

#####################################################################
# Constructor for Registry::Key
#
# Parameters: [pairs]
#   root: Returns the root parameter passed in to new.
#     Valid contents are 'HKLM', 'HKCU', 'HKCR', 'HKMU', and 'HKU'
#   key: The registry key to write to.
#   id, guid, sitename: see WiX::Base::Component
# See http://wix.sourceforge.net/manual-wix3/wix_xsd_registrykey.htm

sub _pre_init : PreInit {
	my ( $self, $args ) = @_;

	# Check parameter needed here.
	unless ( _STRING( $args->{id} ) ) {
		PDWiX->throw('Missing or invalid id param');
	}

	# Apply defaults
	unless ( defined $args->{root} ) {
		$args->{root} = 'HKLM';
	}
	unless ( defined $args->{guid} ) {
		$args->{guid} = $self->generate_guid( $args->{id} );
	}

	return;
} ## end sub _pre_init :

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	# Check params
	unless ( _IDENTIFIER( $root[$object_id] ) ) {
		PDWiX->throw('Invalid root param');
	}
	unless ( $self->check_options( $root[$object_id], @ROOT_OPTIONS ) ) {
		PDWiX->throw('Invalid root param (not a valid registry root key)');
	}
	unless ( _STRING( $key[$object_id] ) ) {
		PDWiX->throw('Missing or invalid subkey param');
	}

	return $self;
} ## end sub _init :

#####################################################################
# Main Methods

########################################
# add_registry_entry($name, $value, $action, $value_type)
# Parameters:
#   $name, $value, $action, $value_type: See Registry::Entry->entry.
# Returns:
#   Object being called. (chainable)

sub add_registry_entry {
	my ( $self, $name, $value, $action, $value_type ) = @_;

	# Parameters checked in Registry::Entry->new

	# Pass this on to the new entry.
	$self->add_entry(
		Perl::Dist::WiX::Registry::Entry->entry(
			$name, $value, $action, $value_type
		) );

	return $self;
} ## end sub add_registry_entry

########################################
# is_key($root, $key)
# Parameters:
#   $root: Root to compare against.
#   $key: Key to compare against.
# Returns:
#   True if this is the object representing $root and $key.

sub is_key {
	my ( $self, $root, $key ) = @_;
	my $object_id = ${$self};

	unless ( _IDENTIFIER($root) ) {
		PDWiX->throw('Missing or invalid root param');
	}
	unless ( _STRING($key) ) {
		PDWiX->throw('Missing or invalid subkey param');
	}

	return 0 if ( uc $key  ne uc $key[$object_id] );
	return 0 if ( uc $root ne uc $root[$object_id] );
	return 1;
} ## end sub is_key

########################################
# as_string
# Parameters:
#    None
# Returns:
#   String representation of the <Component> and <RegistryKey> tags
#   represented by this object, and the <RegistryValue> tags contained
#   by this object.

sub as_string {
	my $self      = shift;
	my $object_id = ${$self};

	# Short-circuit.
	return q{} if ( scalar @{ $self->get_entries } == 0 );

	$root[$object_id] = uc $root[$object_id];

	my $answer = $self->as_start_string();

	$answer .= <<"END_OF_XML";
  <RegistryKey Root='$root[$object_id]' Key='$key[$object_id]'>
END_OF_XML

	$answer .= $self->Perl::Dist::WiX::Base::Component::as_string(4);

	$answer .= <<"END_OF_XML";
  </RegistryKey>
</Component>
END_OF_XML

	return $answer;
} ## end sub as_string

1;
